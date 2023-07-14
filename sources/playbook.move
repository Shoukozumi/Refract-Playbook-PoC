module playbook::SftFramework {
    // Sui Move Library
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::package;
    use sui::display;
    use sui::object::{Self, UID, ID};
    use sui::event;
    use sui::url::{Self, Url, inner_url};
    use sui::address;

    // Standard Move Library
    use std::string::{Self, String, utf8, bytes, from_ascii};
    // use std::ascii;
    // use std::option;
    use std::type_name;
    // use std::vector;

    // My own stuff
    use playbook::utils;

    // Error codes
    const EInsufficientFund: u64 = 201;  // Takasaki Chidori's birthday
    const ENotCreator: u64 = 917;  // Yaegaki Erika's birthday
    const ENonZeroFund: u64 = 106;  // Yatsushiro Yuzuriha's birthday
    const ENotSameSFT: u64 = 1017;  // Komikado Nerine's birthday

    // Semi-Fungible Token Definitions
    struct Sft has key, store {
        id: UID,
        name: String,
        url: Url,
        thumbnail_url: Url,
        description: String,
        creator_name: String,

        // object_link: ID,
        // TODO: store metadata as object reference instead so metadata can be updated across all SFT instances
        // TODO: add field "link" to allow general object wrapping

        quantity: u64,
        metadata: String,  // JSON string to represent additional general purpose metadata

        // Unique identifier fields for comparing SFT
        symbol: String,
        creator: address,
    }

    // Semi-Fungible Token Mint Capability Definition
    struct SftMintPermitCap has key, store {
        id: UID,
        creator: address,
    }

    // --- START SFT Minted Event ---
    struct SftMintedEvent has copy, drop {
        object_id: ID,
        symbol: String,
        quantity: u64,
        creator: address,

        by_permit: bool,
    }
    // --- END SFT Minted Event ---


    // --- START Set Display Standards---
    struct SFTFRAMEWORK has drop { }

    #[allow(unused_function)]
    fun init(otw: SFTFRAMEWORK, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx); // Publisher object to prove ownership

        let display_keys = vector[
            utf8(b"name"),
            utf8(b"image_url"),
            utf8(b"thumbnail_url"),
            utf8(b"description"),
            utf8(b"creator"),

            // utf8(b"link")
        ];
        let display_vals = vector[
            utf8(b"{name} ({quantity})"),
            utf8(b"{url}"),
            utf8(b"{thumbnail_url}"),
            utf8(b"{description}"),
            utf8(b"{creator_name} ({creator})"),

            // utf8(b"{object_link}")
        ];

        let display = display::new_with_fields<Sft>(&publisher, display_keys, display_vals, ctx);
        display::update_version(&mut display); // Update the display version

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));

        // TODO: Generate Management Capabilities
    }
    // --- END Set Display Standards---


    // --- START SFT operations ---
    // Mint a new SFT
    public entry fun mint_sft(
        name: vector<u8>,
        image_url: vector<u8>,
        thumbnail_url: vector<u8>,
        description: vector<u8>,
        quantity: u64,
        sft_id: vector<u8>,
        creator_name: vector<u8>,

        metadata: vector<u8>,

        ctx: &mut TxContext
    ) {
        let sender: address = tx_context::sender(ctx);

        // Mint the SFT
        let sft_uid: UID = object::new(ctx);
        let fresh_sft: Sft = Sft {
            id: sft_uid,
            name: utf8(name),
            url: url::new_unsafe_from_bytes(image_url),
            thumbnail_url: url::new_unsafe_from_bytes(thumbnail_url),
            description: utf8(description),
            creator_name: utf8(creator_name),

            quantity,
            metadata: utf8(metadata),

            // object_link: object::uid_to_inner(sft_uid),  // point to self first

            symbol: utf8(sft_id),
            creator: sender,
        };

        // Broadcast the SFT minted event
        event::emit(
            SftMintedEvent {
                object_id: object::id(&fresh_sft),
                symbol: fresh_sft.symbol,
                quantity: fresh_sft.quantity,
                creator: fresh_sft.creator,

                by_permit: false,
            }
        );

        // Transfer the SFT to the sender
        transfer::public_transfer(fresh_sft, sender);
    }


    // SftPermitCap minted event
    struct SftPermitCapMintedEvent has copy, drop {
        object_id: ID,
        creator: address,
    }

    // Mint a minting permit for a specific creator address
    public fun mint_permit(ctx: &mut TxContext): SftMintPermitCap {
        let sender: address = tx_context::sender(ctx);

        // Mint the permit
        let permit_uid: UID = object::new(ctx);
        let permit: SftMintPermitCap = SftMintPermitCap {
            id: permit_uid,
            creator: sender,
        };

        // Broadcast the permit minted event
        event::emit(
            SftPermitCapMintedEvent {
                object_id: object::id(&permit),
                creator: sender,
            }
        );

        permit
    }

    public entry fun mint_permit_to_address(ctx: &mut TxContext) {
        let sender: address = tx_context::sender(ctx);

        // Transfer the permit to the sender
        transfer::public_transfer(mint_permit(ctx), sender);
    }

    // Mint a new SFT using a minting permit, normally called by another smart contract
    public entry fun permit_mint_sft(
        permit: &SftMintPermitCap,
        receiver: address,

        name: vector<u8>,
        image_url: vector<u8>,
        thumbnail_url: vector<u8>,
        description: vector<u8>,
        quantity: u64,
        item_uid: vector<u8>,
        creator_name: vector<u8>,

        metadata: vector<u8>,

        ctx: &mut TxContext
    ) {

        // Mint the SFT
        let sft_uid: UID = object::new(ctx);
        let fresh_sft: Sft = Sft {
            id: sft_uid,
            name: utf8(name),
            url: url::new_unsafe_from_bytes(image_url),
            thumbnail_url: url::new_unsafe_from_bytes(thumbnail_url),
            description: utf8(description),
            creator_name: utf8(creator_name),

            quantity,
            metadata: utf8(metadata),

            // object_link: object::uid_to_inner(sft_uid),  // point to self first

            symbol: utf8(item_uid),
            creator: permit.creator,
        };

        // Broadcast the SFT minted event
        event::emit(
            SftMintedEvent {
                object_id: object::id(&fresh_sft),
                symbol: fresh_sft.symbol,
                quantity: fresh_sft.quantity,
                creator: fresh_sft.creator,

                by_permit: true,
            }
        );

        // Transfer the SFT to the sender
        transfer::public_transfer(fresh_sft, receiver);
    }

    // Mint a new SFT with the same properties as an existing SFT
    public entry fun permit_clone_sft(
        permit: &SftMintPermitCap,
        target_sft: &Sft,
        quantity: u64,
        receiver: address,

        ctx: &mut TxContext
    ) {
        permit_mint_sft(
            permit,
            receiver,

            *bytes(&target_sft.name),
            *bytes(&from_ascii(inner_url(&target_sft.url))),
            *bytes(&from_ascii(inner_url(&target_sft.thumbnail_url))),
            *bytes(&target_sft.description),
            quantity,
            *bytes(&target_sft.symbol),
            *bytes(&target_sft.creator_name),

            *bytes(&target_sft.metadata),

            ctx
        );
    }

    // Burn the SFT
    public entry fun burn_sft(
        sft: Sft,
        ctx: &mut TxContext
    ) {
        let sender: address = tx_context::sender(ctx);

        assert!(sender == sft.creator, ENotCreator);  // Check if the sender is the creator of the SFT

        let Sft {id, name: _, url: _, thumbnail_url: _, description: _, creator_name: _,
                 quantity: _, metadata: _, symbol: _, creator: _ } = sft;
        object::delete(id)
    }

    // Split an SFT object A into two objects A and B,
    // where A.quantity == sft.quantity - split_quantity && B.quantity == split_quantity
    public entry fun split(
        sft: &mut Sft,
        split_quantity: u64,
        ctx: &mut TxContext
    ) {
        let sender: address = tx_context::sender(ctx);

        assert!(sft.quantity >= split_quantity, EInsufficientFund);  // Check if the sender has enough fund to split

        let new_sft: Sft = Sft {  // Split new SFT from the original SFT
            id: object::new(ctx),
            name: sft.name,
            url: sft.url,
            thumbnail_url: sft.thumbnail_url,
            description: sft.description,
            creator_name: sft.creator_name,

            quantity: split_quantity,
            metadata: sft.metadata,

            symbol: sft.symbol,
            creator: sft.creator,
        };
        sft.quantity = sft.quantity - split_quantity;  // Decrement the original SFT's quantity
        transfer::public_transfer(new_sft, sender);  // Send new split to sender
    }

    // Move some quantity of SFT from one object A to another object B,
    // where A.quantity =- move_quantity && B.quantity += move_quantity
    public entry fun move_fund(
        sft_from: &mut Sft,
        sft_to: &mut Sft,
        move_quantity: u64,
        ctx: &mut TxContext
    ) {
        assert!(is_same(sft_from, sft_to, ctx), ENotSameSFT);  // Check if the two SFTs are the same type
        assert!(sft_from.quantity >= move_quantity, EInsufficientFund);  // Check if the sender has enough fund to move

        sft_from.quantity = sft_from.quantity - move_quantity;  // Decrement the original SFT's quantity
        sft_to.quantity = sft_to.quantity + move_quantity;  // Increment the new SFT's quantity
    }

    // Join two SFT objects A and B into one object A,
    // where A.quantity = A.quantity + B.quantity && B.quantity = 0
    public entry fun join(
        sft_a: &mut Sft,
        sft_b: &mut Sft,
        ctx: &mut TxContext
    ) {
        assert!(is_same(sft_a, sft_b, ctx), ENotSameSFT);  // Check if the two SFTs are the same type

        sft_b.quantity = sft_b.quantity + sft_a.quantity;  // Increment the main SFT's quantity
        sft_a.quantity = 0;  // Set the zero SFT's quantity to 0
    }

    // Join two SFT objects A and B into one object A and destroy the now emptied B,
    // where A.quantity = A.quantity + B.quantity && B.quantity = 0
    public entry fun join_and_burn_zero(
        sft_a: Sft,
        sft_b: &mut Sft,
        ctx: &mut TxContext
    ) {
        join(&mut sft_a, sft_b, ctx);
        burn_zero(sft_a, ctx);
    }

    // Destroy the emptied SFT object
    public entry fun burn_zero(
        sft_zero: Sft,
        _: &mut TxContext
    ) {
        assert!(sft_zero.quantity == 0, ENonZeroFund);  // Check if the SFT is empty

        let Sft {id, name: _, url: _, thumbnail_url: _, description: _, creator_name: _,
            quantity: _, metadata: _, symbol: _, creator: _ } = sft_zero;
        object::delete(id);
    }

    // Check if two SFT objects are the same (same identifier)
    public fun is_same(
        sft_a: &Sft,
        sft_b: &Sft,
        _: &mut TxContext
    ): bool {
        utils::bytestring_equals(bytes(&sft_a.symbol), bytes(&sft_b.symbol)) &&
        sft_a.creator == sft_b.creator
    }


    // Compare the quantity of two SFT objects A and B,
    // Return value is 0 if A.quantity == B.quantity, 1 if A.quantity < B.quantity, and 2 if A.quantity > B.quantity
    public fun compare(
        sft_a: &Sft,
        sft_b: &Sft,
        ctx: &mut TxContext
    ): u8 {
        assert!(is_same(sft_a, sft_b, ctx), ENotSameSFT);  // Check if the two SFTs are the same type

        if (sft_a.quantity == sft_b.quantity) return 0;
        if (sft_a.quantity < sft_b.quantity) return 1;
        2
    }
    // --- END SFT operations ---


    // --- BEGIN SFT getter and setter ---
    // TODO: let getter return full copied value
    public fun get_name(
        sft: &Sft,
        _: &mut TxContext
    ): &String {
        &sft.name
    }
    public fun get_name_mut(
        sft: &mut Sft,
        ctx: &mut TxContext
    ): &mut String {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        &mut sft.name
    }
    public entry fun set_name(
        sft: &mut Sft,
        name: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        sft.name = utf8(name);
    }

    public fun get_image_url(
        sft: &Sft,
        _: &mut TxContext
    ): &Url {
        &sft.url
    }
    public fun get_image_url_mut(
        sft: &mut Sft,
        ctx: &mut TxContext
    ): &mut Url {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        &mut sft.url
    }
    public entry fun set_image_url(
        sft: &mut Sft,
        image_url: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        sft.url = url::new_unsafe_from_bytes(image_url);
    }

    public fun get_thumbnail_url(
        sft: &Sft,
        _: &mut TxContext
    ): &Url {
        &sft.thumbnail_url
    }
    public fun get_thumbnail_url_mut(
        sft: &mut Sft,
        ctx: &mut TxContext
    ): &mut Url {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        &mut sft.thumbnail_url
    }
    public entry fun set_thumbnail_url(
        sft: &mut Sft,
        thumbnail_url: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        sft.thumbnail_url = url::new_unsafe_from_bytes(thumbnail_url);
    }

    public fun get_description(
        sft: &Sft,
        _: &mut TxContext
    ): &String {
        &sft.description
    }
    public fun get_description_mut(
        sft: &mut Sft,
        ctx: &mut TxContext
    ): &mut String {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        &mut sft.description
    }
    public entry fun set_description(
        sft: &mut Sft,
        description: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        sft.description = utf8(description);
    }

    public fun get_creator_name(
        sft: &Sft,
        _: &mut TxContext
    ): &String {
        &sft.creator_name
    }
    public fun get_creator_name_mut(
        sft: &mut Sft,
        ctx: &mut TxContext
    ): &mut String {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        &mut sft.creator_name
    }
    public entry fun set_creator_name(
        sft: &mut Sft,
        creator_name: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        sft.creator_name = utf8(creator_name);
    }

    public fun get_quantity(
        sft: &Sft,
        _: &mut TxContext
    ): u64 {
        sft.quantity
    }
    public entry fun set_quantity(
        sft: &mut Sft,
        quantity: u64,
        ctx: &mut TxContext
    ) {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        sft.quantity = quantity;
    }

    public fun get_metadata(
        sft: &Sft,
        _: &mut TxContext
    ): &String {
        &sft.metadata
    }
    public fun get_metadata_mut(
        sft: &mut Sft,
        ctx: &mut TxContext
    ): &mut String {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        &mut sft.metadata
    }
    public entry fun set_metadata(
        sft: &mut Sft,
        metadata: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(sft.creator == tx_context::sender(ctx), ENotCreator);  // Check if the sender is the creator of the SFT
        sft.metadata = utf8(metadata);
    }

    public fun get_symbol(
        sft: &Sft,
        _: &mut TxContext
    ): &String {
        &sft.symbol
    }

    public fun get_creator(
        sft: &Sft,
        _: &mut TxContext
    ): address {
        sft.creator
    }

    public fun get_full_sftid(
        sft: &Sft,
        _: &mut TxContext
    ): String {
        let buffer: String = utf8(b"");
        let type_string: String = string::from_ascii(type_name::into_string(type_name::get<Sft>()));
        let creator_string: String = address::to_string(sft.creator);
        let symbol_string: String = utf8(utils::copy_bytestring(string::bytes(&sft.symbol)));
        string::append(&mut buffer, type_string);
        string::append_utf8(&mut buffer, b"::");
        string::append(&mut buffer, creator_string);
        string::append_utf8(&mut buffer, b"::");
        string::append(&mut buffer, symbol_string);
        buffer
    }

    // public entry fun append_identifier_to_description(
    //     sft: &mut Sft,
    //     ctx: &mut TxContext
    // ) {
    //     let identifier: String = get_full_identifier(sft, ctx);
    //     string::append_utf8(&mut sft.description, b"\n\n");
    //     string::append(&mut sft.description, identifier);
    // }
    // --- END SFT getter and setter ---
}


module playbook::utils {
    // use sui::url::{Self, Url};

    use std::vector;
    // use std::string::{Self, String};

    fun get_n_bit(x: u8, n: u8): u8 {
        x << (7 - n) >> 7
    }

    // --- START BYTESTRING UTILS ---
    public fun bytestring_to_uint(v: &vector<u8>): u64 {
        let len = vector::length(v);
        let result: u64 = 0;

        let i = 0;
        while (i < len) {
            let digit: u8 = *vector::borrow(v, i);
            if(digit < 48 || digit > 57) abort 1 ;  // NaN

            result = result * 10 + ((digit as u64) - 48);
            i = i + 1;
        };

        result
    }

    public fun copy_bytestring(original: &vector<u8>): vector<u8> {
        let len = vector::length(original);
        let new_bytestring = vector::empty<u8>();

        let i = 0;
        while (i < len) {
            vector::push_back(&mut new_bytestring, *vector::borrow(original, i));
            i = i + 1;
        };

        new_bytestring
    }

    public fun bytestring_equals(v1: &vector<u8>, v2: &vector<u8>): bool {
        let len1 = vector::length(v1);
        let len2 = vector::length(v2);

        // Early return if lengths are different
        if (len1 != len2) { return false };

        let i = 0;
        while (i < len1) {
            if (*vector::borrow(v1, i) != *vector::borrow(v2, i)) {
                return false
            };
            i = i + 1;
        };

        true
    }

    // Function that spilt the string s into a vector of strings, using the delimiter
    public fun split_bytestring_get_tail(s: &vector<u8>, delimit: u8): vector<u8> {
        let output = vector::empty<u8>();
        let len = vector::length(s);

        let i = len;
        let found = false;
        while (i > 0 && !found) {
            i = i - 1;
            if (*vector::borrow(s, i) == delimit) {
                i = i + 1; // index of the substring first character

                while (i < len) {
                    vector::push_back(&mut output, *vector::borrow(s, i));
                    i = i + 1;
                };

                found = true;
            }
        };

        output
    }

    // --- END BYTESTRING UTILS ---
}

module playbook::CraftingFramework {
    use sui::tx_context::{Self, TxContext};
    use sui::package;
    use sui::dynamic_object_field as dof;
    use sui::table::{Self, Table};
    use sui::object::{Self, UID, ID};
    use sui::display;
    use sui::event;
    use sui::url::{Self, Url, inner_url};
    use sui::address;
    use sui::transfer;

    use std::string::{Self, String, utf8};
    use std::vector;

    use playbook::utils;
    use playbook::SftFramework::{Self, Sft, SftMintPermitCap, get_full_sftid, get_quantity, permit_clone_sft};


    const EDuplicateInputItem: u64 = 316;  // Shirahane Suoh's birthday
    const ENotEnoughInputItem: u64 = 617;  // Kohsaka Mayuri's birthday
    const EParameterMismatch: u64 = 515;  // Hanabishi Rikka's birthday


    struct Recipe has key, store {
        id: UID,
        name: String,
        url: Url,
        thumbnail_url: Url,
        details_url: Url,
        description: String,
        creator_name: String,
        creator: address,

        recipes_input: Table<String, Sft>,  // Uses table for O(1) lookup
        recipes_output: vector<Sft>,

        permit: SftMintPermitCap,
    }


    struct CRAFTINGFRAMEWORK has drop { }  // OTW

    fun init(otw: CRAFTINGFRAMEWORK, ctx: &mut TxContext) {
        // -- START Display Standard ---
        let publisher = package::claim(otw, ctx); // Publisher object to prove ownership

        let display_keys = vector[
            utf8(b"name"),
            utf8(b"image_url"),
            utf8(b"project_url"),
            utf8(b"thumbnail_url"),
            utf8(b"description"),
            utf8(b"creator"),
        ];
        let display_vals = vector[
            utf8(b"{name}"),
            utf8(b"{url}"),
            utf8(b"{details_url}"),
            utf8(b"{thumbnail_url}"),
            utf8(b"{description}"),
            utf8(b"{creator_name} ({creator})"),
        ];

        let display = display::new_with_fields<Recipe>(&publisher, display_keys, display_vals, ctx);
        display::update_version(&mut display); // Update the display version

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
        // --- END Display Standard ---
    }

    public entry fun deploy_recipe(
        name: vector<u8>,
        image_url: vector<u8>,
        thumbnail_url: vector<u8>,
        details_url: vector<u8>,
        description: vector<u8>,
        creator_name: vector<u8>,

        inputs_placeholders: vector<Sft>,
        outputs_placeholders: vector<Sft>,

        permit: SftMintPermitCap,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let recipe = Recipe {
            id: object::new(ctx),
            name: utf8(name),
            url: url::new_unsafe_from_bytes(image_url),
            details_url: url::new_unsafe_from_bytes(details_url),
            thumbnail_url: url::new_unsafe_from_bytes(thumbnail_url),
            description: utf8(description),
            creator_name: utf8(creator_name),
            creator: sender,

            recipes_input: table::new<String, Sft>(ctx),

            recipes_output: outputs_placeholders,

            permit
        };

        // Set the input recipe items
        let i = 0;
        let len = vector::length(&inputs_placeholders);
        while (i < len) {  // Iterate over the recipes and add them to the table for faster access time
            let placeholder: Sft = vector::pop_back(&mut inputs_placeholders);
            table::add(&mut recipe.recipes_input, get_full_sftid(&placeholder, ctx), placeholder);

            i = i + 1;
        };
        vector::destroy_empty(inputs_placeholders);

        // Set the output recipe items
        // let i = 0;
        // let len = vector::length(&outputs_placeholders);
        // while (i < len) {  // Iterate over the recipes and add them to the table for faster access time
        //     let placeholder: Sft = vector::pop_back(&mut outputs_placeholders);
        //     table::add(&mut recipe.recipes_output, get_full_sftid(&placeholder, ctx), placeholder);
        //
        //     i = i + 1;
        // };
        // vector::destroy_empty(outputs_placeholders);

        transfer::freeze_object(recipe);  // Freeze such that anyone can use this recipe
        // TODO: make recipe mutable
    }

    // Take in SFTs and craft new SFTs according to the recipe
    public entry fun craft(recipe: &Recipe, inputs: vector<Sft>, ctx: &mut TxContext) {
        let sender: address = tx_context::sender(ctx);

        let input_recipe: &Table<String, Sft> = &recipe.recipes_input;  // Table of input items with sftid: SFT

        let cache_table = table::new<String, bool>(ctx);  // Cache table used to check for repeated SFTs in input list
        let remaining_input: u64 = table::length(input_recipe);

        let i = 0;
        let len = vector::length(&inputs);
        while(i < len) {  // Iterate for each of the user input
            let input: &Sft = vector::borrow(&inputs, i);

            let sftid: String = get_full_sftid(input, ctx);  // Unique identifier of the inputted SFT
            assert!(!table::contains(&cache_table, sftid), EDuplicateInputItem);
            table::add(&mut cache_table, sftid, true);  // Checks that all input items are unique

            assert!(table::contains(input_recipe, sftid), EParameterMismatch);  // Check if the input item is in recipe

            let target_placeholder: &Sft = table::borrow(input_recipe, sftid);

            assert!(get_quantity(input, ctx) == get_quantity(target_placeholder, ctx), ENotEnoughInputItem);  // Check if the input item quanity matches

            remaining_input = remaining_input - 1;
            i = i + 1;
        };

        table::drop(cache_table);  // Destroy the cache table

        assert!(remaining_input == 0, ENotEnoughInputItem);  // Check if all recipe inputs are satisfied


        // Begin the crafting process

        // Transfer all the input SFTs to the creator of the recipe
        while(remaining_input < table::length(input_recipe)) {
            let input: Sft = vector::pop_back(&mut inputs);  // Get the actual input SFT object
            transfer::public_transfer(input, recipe.creator);
            remaining_input = remaining_input + 1;
        };
        vector::destroy_empty(inputs);

        // Iteratively mint and send output SFTs to the sender
        let output_recipe: &vector<Sft> = &recipe.recipes_output;
        let i = 0;
        let len = vector::length(output_recipe);
        while(i < len) {
            let target_placeholder: &Sft = vector::borrow(output_recipe, i);
            permit_clone_sft(
                    &recipe.permit,
            target_placeholder,
            get_quantity(target_placeholder, ctx),
            sender,
            ctx
            );  // Clone the output SFT using the permit
            i = i + 1;
        };
    }

    // struct CraftingPayload has key, store {
    //     id: UID,
    //     creator: address,
    // }
    // // Craftin Payload functions
    // public entry fun create_crafting_payload(ctx: &mut TxContext) {
    //     transfer::public_transfer(CraftingPayload {
    //         id: object::new(ctx),
    //         creator: tx_context::sender(ctx),
    //     }, tx_context::sender(ctx));
    // }
    //
    // // Add an item to the crafting payload
    // public entry fun add_item_to_crafting_payload(payload: &mut CraftingPayload, item: Type) {
    //     dof::add(payload, )
    // }
}


#[test_only]
module playbook::test_crafting {
    // use std::debug;

    #[test]
    public fun test_get_n_bit() {

    }
}