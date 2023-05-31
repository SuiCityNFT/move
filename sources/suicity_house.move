// SPDX-License-Identifier: MIT

module suicitynft::suicity_houses
{
    use std::string::{String, utf8};
    use std::vector;
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::display;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::package;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::dynamic_object_field as dof;
    use sui::dynamic_field as df;
    use sui::ecdsa_k1;
    use suicitynft::suicity_map::{Self, SuiCity, CoordinateData};

    const TOTAL_SUPPLY: u64 = 2468;
    const PUBLIC_SUPPLY: u64 = 1174; // 2468 - (1234 OP PASSPORTS + 60 SUI PASSPORTS)

    /// Error Codes
    const E_TOTAL_SUPPLY_REACHED: u64 = 100;
    const E_PUBLIC_SUPPLY_REACHED: u64 = 101;
    const E_PASS_MINT_NOT_AVAILABLE: u64 = 200;
    const E_PUBLIC_MINT_NOT_AVAILABLE: u64 = 201;
    const E_MORE_THAN_AVAILABLE: u64 = 300;
    const E_NOT_ENOUGH_COIN: u64 = 301;
    const E_NOT_A_PASSPORT_OWNER: u64 = 400;

    struct SuiCityCap has key { id: UID }

    // The HOUSE
    struct House has key, store {
        id: UID,
        token_id: u64,
        x: u64,
        y: u64,
        zone: String,
        config: vector<u64>
    }

    /// Profile object
    struct Profile has key, store { 
        id: UID,
        nick_name: String,
        image_url: String
    }

    /// Interior object
    struct Interior has key, store { id: UID }

    // SuiCity Data (Shared)
    struct SuiCityData has key {
        id: UID,
        current_supply: u64,
        public_claimed: u64,
        pass_mint_allowed: bool,
        paid_mint_allowed: bool,
        price: u64,
        balance: Balance<SUI>,
        houseRegistry: Table<u64, ID> 
    }

    struct HouseLookupResult has drop {
        token_id: u64,
        house_id: ID,
    }

    // === Events ===
    /// Event. Emitted when a furniture added.
    struct FurnitureAdded<phantom T> has copy, drop {
        interior_id: ID,
        furniture_id: ID
    }

    /// Event. Emitted when a furniture is taken off.
    struct FurnitureRemoved<phantom T> has copy, drop {
        interior_id: ID,
        furniture_id: ID,
    }

    /// Event. Emitted when a Citizen claimed a HOUSE.
    struct HouseClaimed has copy, drop {
        id: ID,
        citizen: address
    }

    /// Event. Emitted when Profile basic info edited
    struct ProfileEdited has copy, drop {
        profile_id: ID,
    }

    /// Event. Emitted when a new field added to profile
    struct AddedToPrifile has copy, drop {
        profile_id: ID,
        key: String,
        value: String
    }

    /// Event. Emitted when an exidting field removed form profile
    struct RemovedFromProfile has copy, drop {
        profile_id: ID,
        key: String,
        value: String
    }

    struct SUICITY_HOUSES has drop {}

    fun init(otw: SUICITY_HOUSES, ctx: &mut TxContext) {

        let keys = vector[
            utf8(b"name"),
            utf8(b"link"),
            utf8(b"image_url"),
            utf8(b"coordinate_x"),
            utf8(b"coordinate_y"),
            utf8(b"token_id"),
            utf8(b"houseConfig"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"No. #{token_id}"),
            utf8(b"https://app.suicitynft.fun/houses/{id}"),
            utf8(b"https://app.suicitynft.fun/api/images/v2/{id}"),
            utf8(b"{x}"),
            utf8(b"{y}"),
            utf8(b"{token_id}"),
            utf8(b"{config}"),
            utf8(b"A City that lives on-chain!"),
            utf8(b"https://suicitynft.fun"),
            utf8(b"SuiCityNFT")
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<House>(
            &publisher,keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));

        transfer::transfer(SuiCityCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        transfer::share_object(SuiCityData {
            id: object::new(ctx),
            current_supply: 0,
            public_claimed: 0,
            pass_mint_allowed: true,
            paid_mint_allowed: true,
            price: 20000000000, // 20 SUI
            balance: balance::zero(),
            houseRegistry: table::new(ctx)
        })
    }

    // === Functions ===
    fun mint(
        data: &mut SuiCityData,
        config: vector<u64>,
        suiCity: &SuiCity,
        ctx: &mut TxContext): House
        {

        let house_uid = object::new(ctx);
        let profile_uid = object::new(ctx);
        let interior_uid = object::new(ctx);

        let profile = Profile {    
            id: profile_uid,
            nick_name: utf8(b"_"),
            image_url: utf8(b"https://app.suicitynft.fun/api/images/v2/placeholder")
        };

        let interior = Interior {
            id: interior_uid
        };

        let house_token_id = data.current_supply + 1;

        let coordinateData: CoordinateData = suicity_map::get_coordinate(suiCity, house_token_id);

        let x = suicity_map::get_x(coordinateData);
        let y = suicity_map::get_y(coordinateData);
        let zone = suicity_map::get_zone(coordinateData);

        let house = House {
            id: house_uid,
            token_id: house_token_id,
            x,
            y,
            zone,
            config: config
        };

        dof::add (&mut house.id, 0, profile);
        dof::add (&mut house.id, 1, interior);

        data.current_supply = data.current_supply + 1;

        table::add(&mut data.houseRegistry, house.token_id, object::id(&house));

        house
    }

    /// mint free HOUSE for passport holders.
    /// verify using ecdsa_k1 signature
    public entry fun passport_owner_claim (
        data: &mut SuiCityData,
        amount: u64,
        configs: vector<vector<u64>>,
        suiCity: &SuiCity,
        sig: vector<u8>,
        public_key: vector<u8>,
        msg: vector<u8>,
        ctx: &mut TxContext)
    {

        assert!(data.pass_mint_allowed == true, E_PASS_MINT_NOT_AVAILABLE);

        let pass_owner_verified = ecdsa_k1::secp256k1_verify(&sig, &public_key, &msg, 0);
        assert! (pass_owner_verified == true, E_NOT_A_PASSPORT_OWNER);

        let citizen = tx_context::sender(ctx);

        let i = 0;
        while (i < amount) {
            let config = *vector::borrow<vector<u64>>(&configs, i);
            let house: House = mint(data, config, suiCity, ctx);

            event::emit(HouseClaimed {
                id: object::id(&house),
                citizen: tx_context::sender(ctx)
            });

            i = i + 1;
            transfer::transfer(house, citizen)
        }
    }

    public entry fun public_claim (
        data: &mut SuiCityData,
        payment: Coin<SUI>,
        amount: u64,
        configs: vector<vector<u64>>,
        suiCity: &SuiCity,
        ctx: &mut TxContext)
    {

        assert!(data.paid_mint_allowed == true, E_PUBLIC_MINT_NOT_AVAILABLE);

        let total_public_supply_after_mint = data.public_claimed + amount;
        assert!(total_public_supply_after_mint <= PUBLIC_SUPPLY, E_MORE_THAN_AVAILABLE);

        let total_price = amount * data.price;
        assert!(coin::value(&payment) >= total_price, E_NOT_ENOUGH_COIN);

        let citizen = tx_context::sender(ctx);

        coin::put(&mut data.balance, payment);

        let i = 0;
        while (i < amount) {
            let config = *vector::borrow<vector<u64>>(&configs, i);
            let house: House = mint(data, config, suiCity, ctx);

            event::emit(HouseClaimed {
                id: object::id(&house),
                citizen: tx_context::sender(ctx)
            });

            data.public_claimed = data.public_claimed + 1;
            i = i + 1;

            transfer::transfer(house, citizen)
        }
    }

    /// Fetch selected house object ids
    public entry fun get_houses_by_token_ids( data: &SuiCityData, lookup_token_ids: vector<u64>): vector<HouseLookupResult> {

        let houseLookupResults = vector::empty<HouseLookupResult>();
        let length = vector::length(&lookup_token_ids);

        let i = 0;

        while ( i < length ) {

            let lookup_token_id = *vector::borrow(&lookup_token_ids, i);

            if ( table::contains(&data.houseRegistry, lookup_token_id) ) {
                let house_id = *table::borrow(&data.houseRegistry, lookup_token_id);
                let res = HouseLookupResult { 
                    token_id: lookup_token_id,
                    house_id: house_id
                };
                vector::push_back(&mut houseLookupResults, res);
            };
            i = i + 1
        };
        return houseLookupResults
    }

    /// Fetch all houses object Ids
    public entry fun get_all_houses (data: &SuiCityData): vector<HouseLookupResult> {

        let houseLookupResults = vector::empty<HouseLookupResult>();

        let i = 0;
        
        while (i < data.current_supply) {

            let house_id = *table::borrow(&data.houseRegistry, i);
            let res = HouseLookupResult {
                token_id: i,
                house_id: house_id
            };

            vector::push_back(&mut houseLookupResults, res);
            i = i + 1
        };

        houseLookupResults
    }

    // === Profile Utilities ===
    // Edit profile basic info 
    public entry fun edit_profile (house: &mut House, nick_name: vector<u8>, image_url: vector<u8>) {

        let profile: &mut Profile = dof::borrow_mut(&mut house.id, 0);  //Only Profile object has Name: 0

        profile.nick_name = utf8(nick_name);
        profile.image_url = utf8(image_url);

        event::emit(ProfileEdited {
            profile_id: object::uid_to_inner(&profile.id)
        })
    }

    // Add new df to profile
    public entry fun add_to_profile(house: &mut House, name: vector<u8>, value: vector<u8>) {

        let profile: &mut Profile = dof::borrow_mut(&mut house.id, 0);  //Only Profile object has Name: 0

        let added_key = utf8(name);
        let added_value = utf8(value);

        event::emit(AddedToPrifile {
            profile_id: object::uid_to_inner(&profile.id),
            key: *&added_key,
            value: *&added_value
        });

        df::add (&mut profile.id, utf8(name) , utf8(value))
    }

    // Remove existing df from profile
    public entry fun remove_from_profile (house: &mut House, name: vector<u8>) {

        let profile: &mut Profile = dof::borrow_mut(&mut house.id, 0);
        let removed_key = utf8(name);
        let removed_value = df::remove(&mut profile.id, *&removed_key);

        event::emit(RemovedFromProfile {
            profile_id: object::uid_to_inner(&profile.id),
            key: *&removed_key,
            value: removed_value
        })
    }

    // === Admin control panel ===
    public entry fun start_paid_mint(_: &SuiCityCap, data: &mut SuiCityData) {
        data.paid_mint_allowed = true
    }

    public entry fun stop_paid_mint(_: &SuiCityCap, data: &mut SuiCityData) {
        data.paid_mint_allowed = false
    }

    public entry fun start_pass_mint(_: &SuiCityCap, data: &mut SuiCityData) {
        data.pass_mint_allowed = true
    }

    public entry fun stop_pass_mint(_: &SuiCityCap, data: &mut SuiCityData) {
        data.pass_mint_allowed = false
    }

    // === HOUSE utilities ===
    /// Edit house config
    public entry fun edit_config(house: &mut House, new_config: vector<u64>) {
        house.config = new_config
    }

    /// Every furniture which has <key + store> could be attached Interior.
    public entry fun add_furniture<T: key + store> (house: &mut House, furniture: T)  {
        let interior: &mut Interior = dof::borrow_mut(&mut house.id, 1); // Only Interior object has Name: 1
        event::emit(FurnitureAdded<T> {
            interior_id: object::id(interior),
            furniture_id: object::id(&furniture)
        });
        dof::add(&mut interior.id, object::id(&furniture), furniture)
    }

    /// Remove furniture from Interior.
    public entry fun remove_furniture<T: key + store> (house: &mut House, furniture_id: ID, ctx: &TxContext) {
        let interior: &mut Interior = dof::borrow_mut(&mut house.id, 1); // Only Interior object has Name: 1
        event::emit(FurnitureRemoved<T> {
            interior_id: object::id(interior),
            furniture_id: *&furniture_id
        });
        transfer::public_transfer(dof::remove<ID, T>(&mut interior.id, furniture_id), tx_context::sender(ctx));
    }

    public entry fun withdraw (_: &SuiCityCap, data: &mut SuiCityData, ctx: &mut TxContext) {
        let amount = balance::value(&data.balance);
        let profits = coin::take(&mut data.balance, amount, ctx);
        transfer::public_transfer(profits, tx_context::sender(ctx))
    }

    // === TESTS ===
    #[test]
    fun mint_and_test_token_1() {

        use sui::tx_context;
        use sui::transfer;
        use sui::table;
        use suicitynft::suicity_map;

        let ctx = tx_context::dummy();

        let citizen = @0xA;
        let creator = @0xB;

        // Create SuiCity
        let suiCity = suicity_map::createSuiCity(&mut ctx);

        // Create SuiCityData
        let data = SuiCityData{
                id: object::new(&mut ctx),
                current_supply: 0,
                public_claimed: 0,
                pass_mint_allowed: true,
                paid_mint_allowed: true,
                price: 20000000000, // 20 SUI
                balance: balance::zero(),
                houseRegistry: table::new(&mut ctx)
        };

        // Fake config
        let config: vector<u64> = vector[0,0,0,0,0,0,0,0,0,0];

        let house: House = mint(&mut data, config, &suiCity, &mut ctx);

            assert!(house.x == 6 && house.y == 2, 0);
            assert!(house.token_id == 1, 1);
            assert!(data.current_supply == 1, 2);

            transfer::transfer(house, citizen);
            transfer::transfer(data, creator);
            transfer::public_transfer(suiCity, creator)
        }


    #[test]
    fun multiple_mint() {

        use sui::tx_context;
        use sui::transfer;
        use std::debug;
        use sui::table;
        use suicitynft::suicity_map;

        let ctx = tx_context::dummy();

        let citizen = @0xA;
        let creator = @0xB;

        // Create SuiCity
        let suiCity = suicity_map::createSuiCity(&mut ctx);

        // Create SuiCityData
        let data = SuiCityData{
                id: object::new(&mut ctx),
                current_supply: 0,
                public_claimed: 0,
                pass_mint_allowed: true,
                paid_mint_allowed: true,
                price: 20000000000, // 20 SUI
                balance: balance::zero(),
                houseRegistry: table::new(&mut ctx)
        };

        // Storing minted HOUSES for testing purposes
        let houses: vector<House> = vector::empty<House>();

        let amount = 6;

        // Some fake configs
        let configs: vector<vector<u64>> = vector[
            vector[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            vector[2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
            vector[3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
            vector[4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
            vector[5, 5, 5, 5, 5, 5, 5, 5, 5, 5],
            vector[6, 6, 6, 6, 6, 6, 6, 6, 6, 6]
        ];

        let i = 0;
        while ( i < amount ) {
            let config = *vector::borrow<vector<u64>>(&configs, i);
            let house: House = mint(&mut data, config, &suiCity, &mut ctx);

            // Store each HOUSE for tests
            vector::push_back(&mut houses, house);

            i = i + 1;
        };

        let house_2 = vector::borrow(&houses, 1);
        let house_5 = vector::borrow(&houses, 4);

        // Verified with js
        assert!(house_2.x == 7 && house_2.y == 4, 0);
        assert!(house_2.token_id == 2, 1);
        assert!(house_2.config == vector[2, 2, 2, 2, 2, 2, 2, 2, 2, 2], 2);

        // Verified with js
        assert!(house_5.x == 18 && house_2.y == 4, 0);
        assert!(house_5.token_id == 5, 1);
        assert!(house_5.config == vector[5, 5, 5, 5, 5, 5, 5, 5, 5, 5], 2);

        assert!(vector::length(&houses) == 6, 3);
        assert!(data.current_supply == 6, 4);

        let house_2_stored_id = table::borrow(&data.houseRegistry, 1);
        debug::print(house_2_stored_id);
        debug::print(&house_2.id);
        
        let j = 0;
        while (j < amount) {
            let house: House = vector::pop_back(&mut houses);
            transfer::transfer(house, citizen);
            j = j + 1;
        };

        vector::destroy_empty(houses);
        
        transfer::transfer(data, creator);
        transfer::public_transfer(suiCity, creator)
    }


    #[test]
    public fun test_utilities(){
        use sui::test_scenario;
        use sui::dynamic_field as df;
        use sui::dynamic_object_field as dof;
        use suicitynft::suicity_map::{Self, SuiCity};

        // Create test addresses
        let creator = @0xC;
        let citizenA = @0xA;

        let data: SuiCityData;
        let suiCity: SuiCity;

        // 1st transaction: emulate init suicity_house
        let scenario_val = test_scenario::begin(creator);
        let scenario = &mut scenario_val;

        {
            data = SuiCityData{
                id: object::new(test_scenario::ctx(scenario)),
                current_supply: 0,
                public_claimed: 0,
                pass_mint_allowed: true,
                paid_mint_allowed: true,
                price: 20000000000, // 20 SUI
                balance: balance::zero(),
                houseRegistry: table::new(test_scenario::ctx(scenario))
            };
        };

        // 2nd transaction: emulate init suicity_map
        test_scenario::next_tx(scenario, creator);
        let scenario = &mut scenario_val;

        {
            suiCity = suicity_map::createSuiCity(test_scenario::ctx(scenario));
        };

        // 3rd transaction: mint
        test_scenario::next_tx(scenario, citizenA);

        {
            let amount = 1;

            // Some fake configs
            let configs: vector<vector<u64>> = vector[
                vector[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            ];

            let i = 0;
            while ( i < amount ) {
                let config = *vector::borrow<vector<u64>>(&configs, i);
                let house: House = mint(&mut data, config, &suiCity, test_scenario::ctx(scenario));

                transfer::transfer(house, citizenA);

                i = i + 1;
            };
        };

        // 4th trarnsaction: editt profile basic info
        test_scenario::next_tx(scenario, citizenA);

        {
            let house = test_scenario::take_from_sender<House>(scenario);

            let nick_name: vector<u8> = vector[97, 97, 97];
            let image_url: vector<u8> = vector[98, 98, 98];

            edit_profile(&mut house, nick_name, image_url);
            test_scenario::return_to_sender(scenario, house);
        };

        // 5th transaction: add first field to profile
        test_scenario::next_tx(scenario, citizenA);

        {
            let house = test_scenario::take_from_sender<House>(scenario);

            let key: vector<u8> = vector[99, 99, 99];
            let value: vector<u8> = vector[100, 100, 100];

            add_to_profile(&mut house, key, value);
            test_scenario::return_to_sender(scenario, house);
        };

        // 6th transaction: add another field to profile
        test_scenario::next_tx(scenario, citizenA);

        {
            let house = test_scenario::take_from_sender<House>(scenario);

            let key: vector<u8> = vector[101, 101, 101];
            let value: vector<u8> = vector[102, 102, 102];

            add_to_profile(&mut house, key, value);

            test_scenario::return_to_sender(scenario, house);
        };
        // 6th transaction: some tests
        test_scenario::next_tx(scenario, citizenA);

        {
            let house = test_scenario::take_from_sender<House>(scenario);
            let profile: &mut Profile = dof::borrow_mut(&mut house.id, 0);

            // Some tests
            assert!(df::exists_(&profile.id, utf8(b"eee")) == true, 0);
            
            let df_2 = *df::borrow_mut(&mut profile.id, utf8(b"eee"));
            assert!(df_2 == utf8(b"fff"), 1);

            test_scenario::return_to_sender(scenario, house);
        };

        // 8th transaction: remove 2nd field from profile
        test_scenario::next_tx(scenario, citizenA);

        {
            let house = test_scenario::take_from_sender<House>(scenario);

            let key: vector<u8> = vector[101, 101, 101];

            remove_from_profile(&mut house, key);
            test_scenario::return_to_sender(scenario, house);
        };

        // 9th transaction: edit config
        test_scenario::next_tx(scenario, citizenA);

        {
            let house = test_scenario::take_from_sender<House>(scenario);

            let new_config: vector<u64> = vector[2, 2, 2, 2, 2, 2, 2, 2, 2, 2];

            edit_config(&mut house, new_config);
            test_scenario::return_to_sender(scenario, house);
        };

        // 10th transaction: test
        test_scenario::next_tx(scenario, citizenA);

        {
            let house = test_scenario::take_from_sender<House>(scenario);
            let profile: &mut Profile = dof::borrow_mut(&mut house.id, 0);


            let df_1 = *df::borrow_mut(&mut profile.id, utf8(b"ccc"));
            
            let new_config = vector[2, 2, 2, 2, 2, 2, 2, 2, 2, 2];

            // Tests
            assert!(&mut house.config == &mut new_config, 2);
            assert!(profile.nick_name == utf8(b"aaa"), 3);
            assert!(profile.image_url == utf8(b"bbb"), 4);
            assert!(df_1 == utf8(b"ddd"), 5);
            assert!(df::exists_(&profile.id, utf8(b"eee")) == false, 6);

            test_scenario::return_to_sender(scenario, house);
            transfer::transfer(data, creator);
            transfer::public_transfer(suiCity, creator);
        };
        test_scenario::end(scenario_val);
    }
}
