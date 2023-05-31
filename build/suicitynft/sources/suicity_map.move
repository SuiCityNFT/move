module suicitynft::suicity_map {
    use std::string::{String, utf8};
    use std::vector;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::package;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    const TOTAL_SUPPLY: u64 = 2468;

    struct CoordinateData has copy, drop {
        id: ID,
        x: u64,
        y: u64,
        zone: String
    }

    struct Patch has copy, store {
        w: u64,
        h: u64,
        x: u64,
        y: u64,
        population: u64,
    }

    struct Town has store {
        section: u64,
        name: String,
        population: u64,
        patches: vector<Patch>
    }

    struct SuiCity has key, store {
        id: UID,
        population: u64,
        towns: vector<Town>
    }

    struct MapCreated has copy, drop { id: ID }

    struct SUICITY_MAP has drop {}

    fun init (otw: SUICITY_MAP, ctx: &mut TxContext) {

        let publisher = package::claim(otw, ctx);
        transfer::public_transfer(publisher, tx_context::sender(ctx));

        let suiCity: SuiCity = createSuiCity(ctx);

        transfer::share_object(suiCity)
    }

    public fun createSuiCity(ctx: &mut TxContext): SuiCity {
        // Cypress Hill 
        let section_1_patch_0 = Patch {
            w: 9,
            h: 9,
            x: 6,
            y: 0,
            population: 81
        };

        let section_1_patch_1 = Patch {
            w: 5,
            h: 7,
            x: 15,
            y: 2,
            population: 35
        };

        let section_1 = Town {
            section: 1,
            name: utf8(b"Cypress Hill"),
            population: 116,
            patches: vector[ section_1_patch_0, section_1_patch_1 ]
        };

        // Blueberry Estate
        let section_2_patch_0 = Patch {
            w: 9,
            h: 6,
            x: 28,
            y: 3,
            population: 54
        };

        let section_2_patch_1 = Patch {
            w: 6,
            h: 6,
            x: 37,
            y: 0,
            population: 36
        };

        let section_2_patch_2 = Patch {
            w: 4,
            h: 3,
            x: 43,
            y: 0,
            population: 12
        };

        let section_2 = Town {
            section: 2,
            name: utf8(b"Blueberry Estate"),
            population: 102,
            patches: vector[ section_2_patch_0, section_2_patch_1, section_2_patch_2 ]
        };

        // Alphabet City
        let section_3_patch_0 = Patch {
            w: 1,
            h: 9,
            x: 47,
            y: 0,
            population: 9
        };

        let section_3_patch_1 = Patch {
            w: 8,
            h: 11,
            x: 48,
            y: 0,
            population: 88
        };

        let section_3_patch_2 = Patch {
            w: 5,
            h: 6,
            x: 56,
            y: 5,
            population: 30
        };

        let section_3 = Town {
            section: 3,
            name: utf8(b"Alphabet City"),
            population: 127,
            patches: vector[ section_3_patch_0, section_3_patch_1, section_3_patch_2 ]
        };

        // SuiSee
        let section_4_patch_0 = Patch {
            w: 8,
            h: 11,
            x: 61,
            y: 7,
            population: 88
        };

        let section_4_patch_1 = Patch {
            w: 2,
            h: 6,
            x: 69,
            y: 9,
            population: 12
        };

        let section_4_patch_2 = Patch {
            w: 2,
            h: 7,
            x: 59,
            y: 11,
            population: 14
        };

        let section_4 = Town {
            section: 4,
            name: utf8(b"SuiSee"),
            population: 114,
            patches: vector[ section_4_patch_0, section_4_patch_1, section_4_patch_2 ]
        };

        // Oceanmile
        let section_5_patch_0 = Patch {
            w: 11,
            h: 11,
            x: 48,
            y: 11,
            population: 121
        };

        let section_5_patch_1 = Patch {
            w: 3,
            h: 9,
            x: 45,
            y: 13,
            population: 27
        };

        let section_5 = Town {
            section: 5,
            name: utf8(b"Oceanmile"),
            population: 148,
            patches: vector[ section_5_patch_0, section_5_patch_1 ]
        };

        // Sunflower Fields
        let section_6_patch_0 = Patch {
            w: 14,
            h: 11,
            x: 23,
            y: 9,
            population: 154
        };

        let section_6_patch_1 = Patch {
            w: 1,
            h: 9,
            x: 37,
            y: 11,
            population: 9
        };

        let section_6_patch_2 = Patch {
            w: 2,
            h: 6,
            x: 38,
            y: 14,
            population: 12
        };

        let section_6_patch_3 = Patch {
            w: 5,
            h: 4,
            x: 40,
            y: 16,
            population: 20
        };

        let section_6 = Town {
            section: 6,
            name: utf8(b"Sunflower Fields"),
            population: 195,
            patches: vector[ section_6_patch_0, section_6_patch_1, section_6_patch_2, section_6_patch_3 ]
        };

        // Sky Hill
        let section_7_patch_0 = Patch {
            w: 11,
            h: 11,
            x: 12,
            y: 9,
            population: 121
        };

        let section_7 = Town {
            section: 7,
            name: utf8(b"Sky Hill"),
            population: 121,
            patches: vector[ section_7_patch_0 ]
        };

        // Oceanview Heights
        let section_8_patch_0 = Patch {
            w: 13,
            h: 8,
            x: 6,
            y: 20,
            population: 104
        };

        let section_8 = Town {
            section: 8,
            name: utf8(b"Oceanview Heights"),
            population: 104,
            patches: vector[ section_8_patch_0 ]
        };

        // SuiteVille
        let section_9_patch_0 = Patch {
            w: 21,
            h: 4,
            x: 19,
            y: 20,
            population: 84
        };

        let section_9_patch_1 = Patch {
            w: 4,
            h: 4,
            x: 19,
            y: 24,
            population: 16
        };

        let section_9_patch_2 = Patch {
            w: 4,
            h: 4,
            x: 36,
            y: 24,
            population: 16
        };

        let section_9_patch_3 = Patch {
            w: 21,
            h: 4,
            x: 19,
            y: 28,
            population: 84
        };

        let section_9 = Town {
            section: 9,
            name: utf8(b"SuiteVille"),
            population: 200,
            patches: vector[ section_9_patch_0, section_9_patch_1, section_9_patch_2, section_9_patch_3 ]
        };

        // Silver Shore
        let section_10_patch_0 = Patch {
            w: 5,
            h: 16,
            x: 40,
            y: 20,
            population: 80
        };

        let section_10_patch_1 = Patch {
            w: 5,
            h: 5,
            x: 45,
            y: 22,
            population: 25
        };

        let section_10 = Town {
            section: 10,
            name: utf8(b"Silver Shore"),
            population: 105,
            patches: vector[ section_10_patch_0, section_10_patch_1 ]
        };

        // Sapphire Shoals
        let section_11_patch_0 = Patch {
            w: 11,
            h: 8,
            x: 46,
            y: 36,
            population: 88
        };

        let section_11_patch_1 = Patch {
            w: 3,
            h: 1,
            x: 46,
            y: 44,
            population: 3
        };

        let section_11_patch_2 = Patch {
            w: 2,
            h: 1,
            x: 55,
            y: 44,
            population: 2
        };

        let section_11_patch_3 = Patch {
            w: 1,
            h: 1,
            x: 57,
            y: 39,
            population: 1
        };

        let section_11_patch_4 = Patch {
            w: 5,
            h: 9,
            x: 57,
            y: 40,
            population: 45
        };

        let section_11 = Town {
            section: 11,
            name: utf8(b"Sapphire Shoals"),
            population: 139,
            patches: vector[ section_11_patch_0, section_11_patch_1, section_11_patch_2, section_11_patch_3, section_11_patch_4 ]
        };

        // Lakeside
        let section_12_patch_0 = Patch {
            w: 6,
            h: 9,
            x: 34,
            y: 32,
            population: 54
        };

        let section_12_patch_1 = Patch {
            w: 6,
            h: 8,
            x: 40,
            y: 36,
            population: 48
        };

        let section_12 = Town {
            section: 12,
            name: utf8(b"Lakeside"),
            population: 102,
            patches: vector[ section_12_patch_0, section_12_patch_1 ]
        };

        // SuiSprings
        let section_13_patch_0 = Patch {
            w: 6,
            h: 8,
            x: 19,
            y: 32,
            population: 48
        };

        let section_13_patch_1 = Patch {
            w: 9,
            h: 9,
            x: 25,
            y: 32,
            population: 81
        };

        let section_13_patch_2 = Patch {
            w: 3,
            h: 3,
            x: 25,
            y: 41,
            population: 9
        };

        let section_13 = Town {
            section: 13,
            name: utf8(b"SuiSprings"),
            population: 138,
            patches: vector[ section_13_patch_0, section_13_patch_1, section_13_patch_2 ]
        };

        // Moon Heights
        let section_14_patch_0 = Patch {
            w: 19,
            h: 4,
            x: 0,
            y: 28,
            population: 76
        };

        let section_14_patch_1 = Patch {
            w: 11,
            h: 3,
            x: 8,
            y: 32,
            population: 33
        };

        let section_14_patch_2 = Patch {
            w: 7,
            h: 5,
            x: 12,
            y: 35,
            population: 35
        };

        let section_14_patch_3 = Patch {
            w: 4,
            h: 4,
            x: 13,
            y: 40,
            population: 16
        };

        let section_14 = Town {
            section: 14,
            name: utf8(b"Moon Heights"),
            population: 160,
            patches: vector[ section_14_patch_0, section_14_patch_1, section_14_patch_2, section_14_patch_3 ]
        };

        // Silicon Heights
        let section_15_patch_0 = Patch {
            w: 5,
            h: 4,
            x: 0,
            y: 35,
            population: 20
        };

        let section_15_patch_1 = Patch {
            w: 7,
            h: 4,
            x: 2,
            y: 39,
            population: 28
        };

        let section_15_patch_2 = Patch {
            w: 7,
            h: 8,
            x: 3,
            y: 43,
            population: 56
        };

        let section_15_patch_3 = Patch {
            w: 6,
            h: 4,
            x: 10,
            y: 47,
            population: 24
        };

        let section_15 = Town {
            section: 15,
            name: utf8(b"Silicon Heights"),
            population: 128,
            patches: vector[ section_15_patch_0, section_15_patch_1, section_15_patch_2, section_15_patch_3 ]
        };

        // RiverWalk
        let section_16_patch_0 = Patch {
            w: 15,
            h: 10,
            x: 16,
            y: 47,
            population: 150
        };

        let section_16_patch_1 = Patch {
            w: 3,
            h: 3,
            x: 20,
            y: 44,
            population: 9
        };

        let section_16 = Town {
            section: 16,
            name: utf8(b"RiverWalk"),
            population: 159,
            patches: vector[ section_16_patch_0, section_16_patch_1 ]
        };

        // SouthSui
        let section_17_patch_0 = Patch {
            w: 7,
            h: 2,
            x: 31,
            y: 45,
            population: 14
        };

        let section_17_patch_1 = Patch {
            w: 10,
            h: 7,
            x: 31,
            y: 47,
            population: 70
        };

        let section_17_patch_2 = Patch {
            w: 6,
            h: 3,
            x: 31,
            y: 54,
            population: 18
        };

        let section_17_patch_3 = Patch {
            w: 9,
            h: 8,
            x: 37,
            y: 54,
            population: 72
        };

        let section_17 = Town {
            section: 17,
            name: utf8(b"SouthSui"),
            population: 174,
            patches: vector[ section_17_patch_0, section_17_patch_1, section_17_patch_2, section_17_patch_3 ]
        };

        // Cosmos Corner
        let section_18_patch_0 = Patch {
            w: 5,
            h: 2,
            x: 46,
            y: 54,
            population: 10
        };

        let section_18_patch_1 = Patch {
            w: 13,
            h: 6,
            x: 46,
            y: 56,
            population: 78
        };

        let section_18_patch_2 = Patch {
            w: 3,
            h: 2,
            x: 51,
            y: 50,
            population: 6
        };

        let section_18_patch_3 = Patch {
            w: 3,
            h: 2,
            x: 59,
            y: 56,
            population: 6
        };

        let section_18_patch_4 = Patch {
            w: 6,
            h: 4,
            x: 56,
            y: 52,
            population: 24
        };

        let section_18_patch_5 = Patch {
            w: 4,
            h: 3,
            x: 58,
            y: 49,
            population: 12
        };

        let section_18 = Town {
            section: 18,
            name: utf8(b"Cosmos Corner"),
            population: 136,
            patches: vector[ section_18_patch_0, section_18_patch_1, section_18_patch_2, section_18_patch_3, section_18_patch_4, section_18_patch_5 ]
        };

        let suiCity_uid = object::new(ctx);

        event::emit(MapCreated{ id: object::uid_to_inner(&suiCity_uid) });

        SuiCity {
            id: suiCity_uid,
            population: TOTAL_SUPPLY,
            towns: vector[
                section_1,
                section_2,
                section_3,
                section_4,
                section_5,
                section_6,
                section_7,
                section_8,
                section_9,
                section_10,
                section_11,
                section_12,
                section_13,
                section_14,
                section_15,
                section_16,
                section_17,
                section_18
            ]
        }
    }

    public entry fun get_coordinate(suiCity: &SuiCity, tokenId: u64): CoordinateData {

        // a simple pattern to distribute HOUESES
        let global_index = (tokenId * 19) % (TOTAL_SUPPLY + 1);

        let section: u64 = 0;
        let townToSearch = vector::borrow(&suiCity.towns, section);
        let townPopulation = *&townToSearch.population;

        while(global_index > townPopulation) {
            section = section + 1;
            townToSearch = vector::borrow(&suiCity.towns, section);
            townPopulation = townPopulation + townToSearch.population;
        };

        let town_index: u64 = global_index - (townPopulation - townToSearch.population);
        let patches = &townToSearch.patches;

        let patch: u64 = 0;
        let patchToSearch = vector::borrow(patches, patch);
        let patchPopulation = *&patchToSearch.population;

        while (town_index > patchPopulation) {
            patch = patch + 1;
            patchToSearch = vector::borrow(patches, patch);
            patchPopulation = patchPopulation + patchToSearch.population;
        };

        let patch_index = town_index - (patchPopulation - patchToSearch.population);
        let normalized_patch_index = patch_index - 1;

        let x: u64 = (normalized_patch_index % patchToSearch.w) + patchToSearch.x;
        let y: u64 = normalized_patch_index / patchToSearch.w + patchToSearch.y;
        let name = townToSearch.name;

        CoordinateData {
            id: object::id(suiCity),
            x,
            y,
            zone: name
        }
    }

    // Getters
    public fun get_x (coordinateData: CoordinateData): u64 {
        coordinateData.x
    }

    public fun get_y (coordinateData: CoordinateData): u64 {
        coordinateData.y
    }

    public fun get_zone (coordinateData: CoordinateData): String {
        coordinateData.zone
    }

// #[test]
// // 579 TOTAL GAS USED
// fun test_get_single_coordinate() {

//         use sui::tx_context;
//         use sui::transfer;
//         use std::debug;

//         let ctx = tx_context::dummy();

//         //create SuiCity
//         let suiCity: SuiCity = createSuiCity(&mut ctx);
        
//         let coordinate_1 = get_coordinate(&suiCity, 1); // 4 GAS USED
//         let coordinate_2 = get_coordinate(&suiCity, 2000); // 5 GAS USED

//         debug::print(&coordinate_1);
//         debug::print(&coordinate_2);

//         let dummy_address = @0xCAFE;
//         transfer::transfer(suiCity, dummy_address);
// }

// #[test]
// public fun test_get_coordinate () {

//         use sui::tx_context;
//         use std::string::{utf8};
//         use sui::transfer;
//         use std::debug;

//         // Create a dummy TxContext for testing
//         let ctx = tx_context::dummy();


//         //create SuiCity
//         let suiCity: SuiCity = createSuiCity(&mut ctx);

//         let coordinate_1 = get_coordinate(&suiCity, 1);
//         let coordinate_102 = get_coordinate(&suiCity, 102);
//         let coordinate_103 = get_coordinate(&suiCity, 103);
//         let coordinate_1127 = get_coordinate(&suiCity, 1127);
//         let coordinate_2309 = get_coordinate(&suiCity, 2309);
//         let coordinate_2468 = get_coordinate(&suiCity, 2468);

//         // check with js
//         assert!(coordinate_1.x == 6 && coordinate_1.y == 2 , 0);
//         assert!(coordinate_1.zone == utf8(b"Cypress Hill"), 1);

//         assert!(coordinate_102.x == 7 && coordinate_102.y == 45  , 0);
//         assert!(coordinate_102.zone == utf8(b"Silicon Heights"), 1);

//         assert!(coordinate_103.x == 5 && coordinate_103.y == 48  , 0);
//         assert!(coordinate_103.zone == utf8(b"Silicon Heights"), 1);

//         assert!(coordinate_1127.x == 28 && coordinate_1127.y == 36  , 0);
//         assert!(coordinate_1127.zone == utf8(b"SuiSprings"), 1);

//         assert!(coordinate_2309.x == 8 && coordinate_2309.y == 39  , 0);
//         assert!(coordinate_2309.zone == utf8(b"Silicon Heights"), 1);

//         assert!(coordinate_2468.x == 61 && coordinate_2468.y == 54  , 0);
//         assert!(coordinate_2468.zone == utf8(b"Cosmos Corner"), 1);

//         // print on console
//         debug::print(&coordinate_1);
//         debug::print(&coordinate_102);
//         debug::print(&coordinate_103);
//         debug::print(&coordinate_1127);
//         debug::print(&coordinate_2309);
//         debug::print(&coordinate_2468);


//         let dummy_address = @0xCAFE;
//         transfer::transfer(suiCity, dummy_address);
//     }
}