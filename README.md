# The SFT Framework (playbook::SftFramework)

This Move Smart Contract module provides a framework for creating, managing, and interacting with Semi-Fungible Tokens (SFTs).

## What are Semi-Fungible tokens?
Semi-fungible tokens (SFTs) are a unique type of digital asset that blend characteristics of both fungible and non-fungible tokens (NFTs). Unlike NFTs, which are entirely unique and cannot be replaced with any other, SFTs can exist in both states: they can be fungible (supply = n), interchangeable with others of the same type, or non-fungible (supply = 1), unique and irreplaceable. This dual nature makes SFTs a versatile medium for representing ownership of both tangible and intangible items, which can be extremely useful for onboarding existing businesses and their assets onto the blockchain.

In terms of use cases, SFTs can be applied in a variety of contexts. For tangible items, they can be used to denote ownership of limited edition physical goods, where each item is similar but has unique attributes, such as serial numbers or specific features that set them apart. For intangible assets, SFTs can be used in the digital realm to represent things like access rights to certain services, levels of membership in a platform, or even varying tiers of digital collectibles.

The key difference between SFTs and NFTs lies in their interchangeability. While NFTs represent one-of-a-kind assets, making each token unique and non-interchangeable, SFTs have the flexibility to represent assets that are completely unique, partially unique, or not unique at all. This makes SFTs a more general-purpose medium, capable of effectively representing a broader range of assets, from wholly unique pieces of art to items in a series where each piece has some degree of uniqueness, to completely fungible tokens like cryptocurrencies.

SFTs can revolutionize how businesses manage and interact with their assets. They offer instant and seamless transferability, reducing logistical constraints and opening up global markets. Their interoperability can lead to innovative business models, such as cross-industry collaborations. SFTs can also enhance customer engagement by providing tradeable tokens that represent a customer's relationship with a brand. Furthermore, the transparency and traceability of SFTs ensure undeniable proof of authenticity and ownership, crucial for businesses dealing with high-value goods. In essence, SFTs provide businesses with a versatile tool to improve operational efficiency, explore new opportunities, and enhance customer relationships and brand value.

## How does SFT work?
Anyone can mint an SFT by calling the `SftFramework::mint_sft()` function. When minting an SFT, the creator will specify an arbitrary `sft_id` value that uniquely identifies the SFT object. This `sft_id` is used to identify whether two SFT objects represent the same SFT. (i.e. if Object A and Object B have the same creator and sft_id, they are regarded as the same SFT, allowing them to be joined together). It is up to the creator to maintain the `sft_id` unity.

## Try it out for yourself!
Version 0.1.0 of the SftFramework is deployed on the Sui Testnet under the module address [0x93a5ac11c967a8d6f28f485673f6e86e09e91828a7ede74e7e05702bac3c269c](https://suiexplorer.com/object/0x93a5ac11c967a8d6f28f485673f6e86e09e91828a7ede74e7e05702bac3c269c?module=SftFramework&network=testnet) (as of Jul 13, 2023). You can try it out for yourself using the Sui CLI commands described in the following sections after setting the `$PLAYBOOK` environment variable.

```console
export $PLAYBOOK=0x93a5ac11c967a8d6f28f485673f6e86e09e91828a7ede74e7e05702bac3c269c
```

## Module Structure
### Structs:

- `Sft`: Represents a Semi-Fungible Token. It has fields for the token's unique identifier (`id`), `name`, `url`, `thumbnail_url`, `description`, `creator_name`, `quantity`, `metadata`, `symbol`, and `creator`.
- `SftMintPermitCap`: Represents a minting permit capability for a specific creator address. Any object that owns a minting permit can mint SFTs on behalf of the creator of the minting permit. It has fields for the permit's unique identifier (`id`) and the `creator`'s address.
- `SftMintedEvent`: Event emitted when a new SFT is minted. It has fields for the `object_id`, `symbol`, `quantity`, `creator`, and a boolean `by_permit` to indicate if the SFT was minted using a permit.
- `SFTFRAMEWORK`: A One-Time-Witness(OTW) struct used to initialize the display standards for the SFT framework.
- `SftPermitCapMintedEvent`: Event emitted when a new minting permit is minted. It has fields for the `object_id` and the `creator`'s address.

### Functions

This module contains several entry functions for creating and managing SFTs. These include:
- `mint_sft`: Mints a new SFT.
```console
sui client call --function mint_sft --module SftFramework --package $PLAYBOOK --args "<Name of SFT>" "<Image URL>" "<Thumbnail URL>" "<Description>" "<Quantity>" "<SFT ID>" "<Creator Name>" "<JSON Metadata>" --gas-budget 100000000
```
- `mint_permit_to_address`: Mints a new minting permit and transfers it to the sender's address.
```console
sui client call --function mint_permit_to_address --module SftFramework --package $PLAYBOOK --gas-budget 100000000
```
- `permit_mint_sft`: Mints a new SFT using a minting permit.
```console
sui client call --function permit_mint_sft --module SftFramework --package $PLAYBOOK --args "<Permit Object ID>" "<SFT Receiver Address>" "<Name of SFT>" "<Image URL>" "<Thumbnail URL>" "<Description>" "<Quantity>" "<SFT ID>" "<Creator Name>" "<Metadata>" --gas-budget 100000000
```
- `permit_clone_sft`: Mints a new SFT with the same properties as an existing SFT.
```console
sui client call --function permit_clone_sft --module SftFramework --package $PLAYBOOK --args "<Permit Object ID>" "<Clone target SFT Object ID>" "<Quantity>" "<SFT Receiver Address>" --gas-budget 100000000
```
- `burn_sft`: Burns (destroys) an SFT (must be the creator of the SFT).
```console
sui client call --function burn_sft --module SftFramework --package $PLAYBOOK --args "<SFT Object ID>" --gas-budget 100000000
```
- `split`: Splits an SFT object into two objects with different quantities.
```console
sui client call --function split --module SftFramework --package $PLAYBOOK --args "<SFT Object ID>" "<Split Quantity>" --gas-budget 100000000
```
- `move_fund`: Moves some quantity of SFT from one object to another.
```console
sui client call --function move_fund --module SftFramework --package $PLAYBOOK --args "<SFT Object ID From>" "<SFT Object ID To>" "<Move Quantity>" --gas-budget 100000000
```
- `join`: Joins SFT object A into object B.
```console
sui client call --function join --module SftFramework --package $PLAYBOOK --args "<SFT A Object ID>" "<SFT B Object ID>" --gas-budget 100000000
```
- `join_and_burn_zero`: Joins SFT object A into object B and destroys the now emptied object A.
```console
sui client call --function join_and_burn_zero --module SftFramework --package $PLAYBOOK --args "<SFT A Object ID>" "<SFT B Object ID>" --gas-budget 100000000
```
- `burn_zero`: Destroys an emptied SFT object.
```console
sui client call --function burn_zero --module SftFramework --package $PLAYBOOK --args "<Empty SFT Object ID>" --gas-budget 100000000
```

  This module also include some other functions related to SFTs and minting permits:
- `is_same`: Checks if two SFT objects are the same (same SFT string identifier).
- `mint_permit`: Mints a new minting permit for a specific creator address.
- `compare`: Compares the quantity of two SFT objects.
- Getter and setter functions for the `Sft` struct fields. All setter functions are entry functions that can only be called by the SFT's creator. 


# The Crafting Framework (playbook::CraftingFramework)

This module introduces the concept of Crafting, which is the process of combining multiple SFTs to create new SFTs using general-purpose Recipe objects. It provides a framework for creating, managing, and interacting with Recipe objects.

## How does Recipe objects work
Recipe objects are used to define the crafting process. They specify the inputs and outputs SFTs, as well as the quantity of each SFT required to craft the output SFT. Recipes can also contain general purpose logic that will be executed during the crafting process, such as employing psuedorandomness to determine the output SFT's properties.

Recipes can be created by anyone, and they can be deployed to the blockchain for others to use. Once deployed, anyone can craft new SFTs according to the recipe and the crafted SFTs will be signed by the recipe's creator in an asynchronous manner. 

Crafting recipes unlock a new horizon of possibilities for businesses to build gamification logics and richer customer experiences. The general-purpose nature of the SFT and Crafting framework allow maximum freedom in terms of asset interoperability, allowing different businesses to collaborate and create new value. For example, a restaurant can create a recipe that requires a certain amount of SFTs from a specific brand of wine to craft a new SFT that represents a voucher for a free meal at the restaurant. This voucher SFT can then be used to craft a new SFT that represents a free bottle of wine from the same brand. This creates a closed loop of value that can be used to incentivize customers to purchase more wine from the brand and dine at the restaurant. 

## Try it out for yourself!
Version 0.1.0 of the CraftingFramework is deployed on the Sui Testnet under the module address [0x93a5ac11c967a8d6f28f485673f6e86e09e91828a7ede74e7e05702bac3c269c](https://suiexplorer.com/object/0x93a5ac11c967a8d6f28f485673f6e86e09e91828a7ede74e7e05702bac3c269c?module=CraftingFramework&network=testnet) (as of Jul 13, 2023). You can try it out for yourself using the Sui CLI commands described in the following sections after setting the `$PLAYBOOK` environment variable.

```console
export $PLAYBOOK=0x93a5ac11c967a8d6f28f485673f6e86e09e91828a7ede74e7e05702bac3c269c
```

## Module Structure
### Structs

- `Recipe`: Represents a crafting recipe. It has fields for the recipe's unique identifier (`id`), `name`, `url`, `thumbnail_url`, `details_url`, `description`, `creator_name`, `creator`, `recipes_input`, `recipes_output`, and `permit`.
- `CRAFTINGFRAMEWORK`: A One-Time-Witness(OTW) struct used to initialize the crafting framework.

### Public Functions

- `deploy_recipe`: Deploys a new crafting recipe with the supplied parameters. For the specific input parameters, please refer to the code comments.
```console
sui client call --function deploy_recipe --module CraftingFramework --package $PLAYBOOK --args "<Recipe Name>" "<Recipe photo url>" "<Recipe thumbnail url>" "<Recipe details url>" "<Recipe descriptions>" "<Creator name>" '["<Input SFT A Object ID>","<Input SFT B Object ID>",...]' '["<Output SFT A Object ID>","<Output SFT B Object ID>",...]' <Mint Permit Object ID> --gas-budget 100000000
```
- `craft`: Crafts new SFTs according to a given recipe. The inputted crafting materials will be sent to the recipe's creator, and crafting output SFTs will be automatically minted and sent to the crafter. 
```console
sui client call --function craft --module CraftingFramework --package $PLAYBOOK --args "<Recipe ID>" '["<Input SFT A Object ID>","<Input SFT B Object ID>",...]'--gas-budget 100000000`
```

# Utilities Collection (playbook::utils)

This module contains various utility functions that were developed for the SFT and Crafting framework, such as working with bytestrings and other operations. As the SFT and Crafting framework becomes more developed, more utilities will be created and can be used by any other developers in the Move ecosystem, benefiting the entire community.

### Functions

- `get_n_bit`: Returns the nth bit of a byte.
- `bytestring_to_uint`: Converts a bytestring to an unsigned integer.
- `copy_bytestring`: Returns a copy of a bytestring.
- `bytestring_equals`: Checks if two bytestrings are equal.
- `split_bytestring_get_tail`: Splits a bytestring and returns the tail.
