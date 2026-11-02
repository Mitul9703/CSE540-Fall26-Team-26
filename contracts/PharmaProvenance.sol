// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// We use OpenZeppelin's AccessControl library to handle roles.
// This library gives us a tested way for assigning roles to wallet addresses and to check those roles before someone is allowed to do something. 
// We only use it for the role bookkeeping
// All of the supply chain logic below is written by us
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PharmaProvenance
 * @notice This contract tracks a medicine batch from the manufacturer all the way to the patient. 
 *         It records every handoff, lets a regulator certify a batch, flags a batch if it ever gets too warm during shipping, and stores the fingerprint (hash) of each batch's lab certificate. 
 *         The real certificate file is kept off-chain in IPFS.
 *         This is a draft for the Smart Contract Design milestone, so a few parts are kept simple on purpose and will be improved later.
 */
contract PharmaProvenance is AccessControl {

    // Roles -
    // These are the roles a wallet can have. 
    // A wallet requires a right role before it is allowed to call certain functions. 
    // The patient or the public does not need a role because reading the data is open to everyone.
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE  = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant PHARMACY_ROLE     = keccak256("PHARMACY_ROLE");
    bytes32 public constant REGULATOR_ROLE    = keccak256("REGULATOR_ROLE");

    // Types -
    // The stages a batch moves through in order.
    enum Status { Created, Shipped, Received, Dispensed }

    // All the info we keep on-chain for one batch. 
    // Like mentioned in the proposal, the actual certificate file is not stored here. Only its hash is so that later we can check if the off-chain file was modified or not.
    struct Batch {
        uint256 id;
        string  drugName;
        address currentOwner;
        Status  status;
        bool    certified;         // This becomes true after a regulator certifies it
        bool    coldChainBreached; // This becomes true if it ever goes outside the prescribed temperature range while shipping
        string  certificateHash;   // This is the IPFS hash of the lab certificate
        bool    exists;            // This lets us check that a batch is real
    }

    // Storage -
    // This looks up a batch by its ID.
    mapping(uint256 => Batch) private batches;

    // this mapping keeps the list of everyone who has owned a batch in order, so that we can show the full ownership history later.
    mapping(uint256 => address[]) private ownershipHistory;

    // We have set the safe temperature range for the medicine as 2-8 degrees celsius. If a reading falls outside this range, we flag the batch. 
    int256 public constant MIN_TEMP_C = 2;
    int256 public constant MAX_TEMP_C = 8;

    // Events -
    // Events are permanent log entries. The frontend reads these to rebuild a batch's history and once they are written they cannot be changed.
    event BatchRegistered(uint256 indexed id, string drugName, address indexed manufacturer);
    event CustodyTransferred(uint256 indexed id, address indexed from, address indexed to);
    event StatusUpdated(uint256 indexed id, Status newStatus);
    event BatchCertified(uint256 indexed id, address indexed regulator);
    event ColdChainBreached(uint256 indexed id, int256 temperature);

    // Setup -
    // Whoever deploys the contract becomes the admin. The admin is the only one who can hand out roles (using grantRole, which comes from OpenZeppelin), for example making one wallet a Manufacturer and another wallet a Distributor.
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Modifiers -
    // This modifier is used to check if a batch actually exists before we try to do anything with it.
    modifier batchExists(uint256 id) {
        require(batches[id].exists, "Batch does not exist");
        _;
    }

    // Core functions -
    // These are the main functions that allow the different roles to interact with the contract.

    /**
     * @notice Register a brand new batch. Only a Manufacturer can do this. This is the start of the batch's record.
     * @param id a unique number for this batch
     * @param drugName the name of the medicine
     * @param certificateHash the IPFS hash of the lab certificate file
     */
    function registerBatch(uint256 id, string calldata drugName, string calldata certificateHash)
        external
        onlyRole(MANUFACTURER_ROLE)
    {
        // we do not allow two batches with the same ID.
        require(!batches[id].exists, "Batch ID already used");

        // we create the batch record and set the manufacturer as the first owner.
        batches[id] = Batch({
            id: id,
            drugName: drugName,
            currentOwner: msg.sender,
            status: Status.Created,
            certified: false,
            coldChainBreached: false,
            certificateHash: certificateHash,
            exists: true
        });

        // we record the manufacturer as the first entry in the ownership history.
        ownershipHistory[id].push(msg.sender);

        emit BatchRegistered(id, drugName, msg.sender);
    }

    /**
     * @notice Hand the batch over to the next party, for example from the distributor to the pharmacy. Only the current owner can do this.
     * @param id the batch to transfer
     * @param newOwner the wallet that will take custody next
     */
    function transferCustody(uint256 id, address newOwner)
        external
        batchExists(id)
    {
        require(batches[id].currentOwner == msg.sender, "Only the current owner can transfer");
        require(newOwner != address(0), "New owner cannot be the zero address");

        address previousOwner = batches[id].currentOwner;
        batches[id].currentOwner = newOwner;
        ownershipHistory[id].push(newOwner);

        emit CustodyTransferred(id, previousOwner, newOwner);
    }

    /**
     * @notice Update the stage the batch is in, for example from Created to Shipped. Only the current owner can update it.
     * @param id the batch to update
     * @param newStatus the new stage
     */
    function updateStatus(uint256 id, Status newStatus)
        external
        batchExists(id)
    {
        require(batches[id].currentOwner == msg.sender, "Only the current owner can update status");

        batches[id].status = newStatus;
        emit StatusUpdated(id, newStatus);
    }

    /**
     * @notice A regulator certifies that the batch passed its quality check. The regulator never owns the batch, they only vouch for it.
     * @param id the batch to certify
     */
    function certifyBatch(uint256 id)
        external
        onlyRole(REGULATOR_ROLE)
        batchExists(id)
    {
        batches[id].certified = true;
        emit BatchCertified(id, msg.sender);
    }

    /**
     * @notice Record a temperature reading for a batch while it is shipping.
     *         In our project this is called by the simulated oracle script which runs from the current owner's wallet. If the reading is outside the safe range, we flag the batch for good so the problem can never be hidden later.
     * @param id the batch the reading is for
     * @param temperatureCelsius the temperature reading in Celsius
     */
    function recordTemperature(uint256 id, int256 temperatureCelsius)
        external
        batchExists(id)
    {
        require(batches[id].currentOwner == msg.sender, "Only the current owner can record temperature");

        // If it is too warm or too cold, flag it and announce the breach.
        if (temperatureCelsius > MAX_TEMP_C || temperatureCelsius < MIN_TEMP_C) {
            batches[id].coldChainBreached = true;
            emit ColdChainBreached(id, temperatureCelsius);
        }
    }

    // Read functions -
    // These just let anyone read the data. They do not change anything, so they are free to call and open to the public (our Patient/Public role).

    /**
     * @notice Get all the stored details for one batch.
     */
    function getBatch(uint256 id)
        external
        view
        batchExists(id)
        returns (Batch memory)
    {
        return batches[id];
    }

    /**
     * @notice Get the full list of owners for a batch, in order, so the frontend can show the whole ownership history.
     */
    function getHistory(uint256 id)
        external
        view
        batchExists(id)
        returns (address[] memory)
    {
        return ownershipHistory[id];
    }
}
