// SPDX-License-Identifier: MIT

module SuiCityNFT::suicity
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

    const TOTAL_SUPPLY: u64 = 10;
    const PUBLIC_SUPPLY: u64 = 5;

    /// Error Codes
    const E_TOTAL_SUPPLY_REACHED: u64 = 100;
    const E_PUBLIC_SUPPLY_REACHED: u64 = 101;
    const E_PASS_MINT_NOT_AVAILABLE: u64 = 200;
    const E_PUBLIC_MINT_NOT_AVAILABLE: u64 = 201;
    const E_MORE_THAN_AVAILABLE: u64 = 300;
    const E_NOT_ENOUGH_COIN: u64 = 301;
    const E_NOT_A_PASSPORT_OWNER: u64 = 400;
    const E_HOUSE_LOCATED: u64 = 500;

    struct SuiCityCap has key { id: UID }

    // The HOUSE
    struct House has key, store {
        id: UID,
        tokenId: u64,
        x: u64,
        y: u64,
        zone: String,
        config: vector<u8>
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

    // Events
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

    struct SUICITY has drop {}

    fun init(otw: SUICITY, ctx: &mut TxContext) {

        let keys = vector[
            utf8(b"name"),
            utf8(b"link"),
            utf8(b"image_url"),
            utf8(b"coordinate_x"),
            utf8(b"coordinate_y"),
            utf8(b"tokenId"),
            utf8(b"houseCnonfig"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"No. #{tokenId}"),
            utf8(b"https://app.suicitynft.fun/houses/{id}"),
            utf8(b"https://app.suicitynft.fun/api/images/v2/{id}"),
            utf8(b"{x}"),
            utf8(b"{y}"),
            utf8(b"{tokenId}"),
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
    fun mint( data: &mut SuiCityData, config: vector<u8>, ctx: &mut TxContext) {

        let house_uid = object::new(ctx);
        let profile_uid = object::new(ctx);
        let interior_uid = object::new(ctx);

        let house_tokenId = data.current_supply + 1;

        let citizen = tx_context::sender(ctx);

        let profile = Profile {    
            id: profile_uid,
            nick_name: utf8(b"_"),
            image_url: utf8(b"https://app.suicitynft.fun/api/images/v2/placeholder")
        };

        let interior = Interior {
            id: interior_uid
        };

        event::emit(HouseClaimed {
            id: object::uid_to_inner(&house_uid),
            citizen: tx_context::sender(ctx)
        });

        let house = House {
            id: house_uid,
            tokenId: house_tokenId,
            x: 0,
            y: 0,
            zone: utf8(b"__SECTION_ZERO__"),
            config: config
        };

        dof::add (&mut house.id, 0, profile);
        dof::add (&mut house.id, 1, interior);

        data.current_supply = data.current_supply + 1;

        transfer::transfer(house, citizen)
    }

    /// mint free HOUSE for passport holders.
    /// verify using ecdsa_k1 signature
    public entry fun passport_owner_claim (
        data: &mut SuiCityData,
        amount: u64,
        configs: vector<vector<u8>>,
        sig: vector<u8>,
        public_key: vector<u8>,
        msg: vector<u8>,
        ctx: &mut TxContext)
    {

        assert!(data.pass_mint_allowed == true, E_PASS_MINT_NOT_AVAILABLE);

        let pass_owner_verified = ecdsa_k1::secp256k1_verify(&sig, &public_key, &msg, 0);
        assert! (pass_owner_verified == true, E_NOT_A_PASSPORT_OWNER);

        let i = 0;
        while (i < amount) {
            let config = vector::borrow<vector<u8>>(&configs, i);
            mint(data, *config, ctx);
            i = i + 1;
        }
    }

    public entry fun public_claim (
        data: &mut SuiCityData,
        payment: Coin<SUI>,
        amount: u64,
        configs: vector<vector<u8>>,
        ctx: &mut TxContext)
    {

        assert!(data.paid_mint_allowed == true, E_PUBLIC_MINT_NOT_AVAILABLE);

        let total_public_supply_after_mint = data.public_claimed + amount;
        assert!(total_public_supply_after_mint <= PUBLIC_SUPPLY, E_MORE_THAN_AVAILABLE);

        let total_price = amount * data.price;
        assert!(coin::value(&payment) >= total_price, E_NOT_ENOUGH_COIN);

        coin::put(&mut data.balance, payment);

        let i = 0;
        while (i < amount) {
            let config = vector::borrow<vector<u8>>(&configs, i);
            mint(data, *config, ctx);
            data.public_claimed = data.public_claimed + 1;
            i = i + 1;
        }
    }

    /// initialize house - the house has no functionality without initializing
    public entry fun init_house (data: &mut SuiCityData, house: &mut House, x: u64, y: u64, zone: vector<u8>) {

        assert!( x == 0 && y == 0, E_HOUSE_LOCATED); // there is no locatiion with (0,0) in SuiCity

        house.x = x;
        house.y = y;
        house.zone = utf8(zone);

        table::add(&mut data.houseRegistry, house.tokenId, object::uid_to_inner(&mut house.id));
    }

    /// fetch selected house object ids
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

    /// fetch all houses object Ids
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
        return houseLookupResults
    }

    // === Profile Utilities ===
    // edit basic info 
    public entry fun edit_profile (house: &mut House, nick_name: vector<u8>, image_url: vector<u8>) {

        let profile: &mut Profile = dof::borrow_mut(&mut house.id, 0);
        profile.nick_name = utf8(nick_name);
        profile.image_url = utf8(image_url);

        event::emit(ProfileEdited {
            profile_id: object::uid_to_inner(&profile.id)
        })
    }

    // add new df to profile
    public entry fun add_to_profile(house: &mut House, name: vector<u8>, value: vector<u8>) {

        let profile: &mut Profile = dof::borrow_mut(&mut house.id, 0);     //Only Profile object has Name: 0
        let added_key = utf8(name);
        let added_value = utf8(value);

        event::emit(AddedToPrifile {
            profile_id: object::uid_to_inner(&profile.id),
            key: *&added_key,
            value: *&added_value
        });

        df::add (&mut profile.id, utf8(name) , utf8(value))
    }

    // remove existing df from profile
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
    /// edit house config
    public entry fun edit_config(house: &mut House, new_config: vector<u8>) {
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
}