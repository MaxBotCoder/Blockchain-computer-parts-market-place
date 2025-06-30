//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract x {

    mapping(address => bool) public AdminPermissions;
    mapping(address => bool) public DataWritePermissions;

    uint public constant price = 4;

    //Moderator permissions
    mapping(address => bool) public ModeratorPermissions;

    //Verifies if account exists
    mapping(address => bool) public accountAddressValid; //Determines if address has bought an account
    uint public AccountIDs;
    mapping(address => uint) accountAddressToID; //Account address to account ID.
    mapping(address => string) public accountAddressToHandle; //Address to handle.
    mapping(uint => string) accountIDToHandle; //Account ID to handle.
    mapping(string => uint) accountHandleToID; //Account handle to ID
    mapping(string => address) accountHandleToAddress;
    mapping(string => bool) public HandleClaimed;

    //Maximum votes to finish election
    uint public constant MaxVotes = 25;
    uint public constant VoteThreshhold = 14;

    //Numbers of reports accumalated
    uint public constant MaximumGuiltCountPriorToBlaccklisting = 12; //Must be changed prior to deployment.
    mapping(address => uint) public GuiltAccumalated;

    //Verrifies if account has been blacklisted
    mapping(address => bool) public BlackListed;

    //If account has been directly banned by moderator.
    mapping(address => string) public ReasonForBan;

    //Person eledgable for money.
    //automated escrow number has since been fused with globalListingID.

    mapping(address => mapping(uint => mapping(bool => bool))) BuyerOrSeller; //Bool 1 determines if person is involved with transaction bool 2 determines if person is buyer or seller. 
    mapping(address => mapping(uint => bool)) PersonViolatedEscrowTerms; //address belongs to seller, uint is number of the escrow session number bool determines if user has been deceptive.
    mapping(address => mapping(uint => uint)) PersonEledgableForMoney; //address of seller, first uint represents escrow session number, second uint represents quantity of money eledgable for.

    //Amount of time untill seller is eledgable for withdrawing funds from escrow
    uint public constant Escrowithdrawtime = 604800;

    //Listing info
    struct Listing {
        //general info
        uint ItemID;
        uint Price;
        uint ItemType;
        string ListingName;
        uint Quantity;
        uint TransactionTime;
        bool OutOfStock;

        //shipment info
        mapping(address => uint) ItemIDofShippment;
        mapping(address => uint) QuantityofShippment;
        mapping(address => bool) ShipmentStarted;
        mapping(address => bool) Recieved;
    }

    //General
    uint public GlobalListingPageID;
    mapping(uint => address) public SellPageTiedToAddress;
    mapping(uint => Listing) public ListingPage;

    //Specific user
    mapping(address => uint) public PersonalListingNumber;
    mapping(address => mapping(uint => Listing)) public PersonalListingPage;

    //Listing Exists
    mapping(uint => bool) public ListingExists;
    mapping(address => mapping(uint => bool)) public PersonalListingExists;

    //Item ID
    uint public ItemID;
    mapping(address => uint) public ItemIDTiedToAddress;

    //Item Types
    uint public MaximumItemTypes;

    //Data writing permissions
    mapping(address => bool) public ShippingDataWritePermissionsGranted;

    //Escrow session tied to listing.
    mapping(uint => uint) EscrowSessionTiedToListing; //first uint is the number of listing, second uint represents escrow session number.

    modifier PriceToSignUp (string memory _Handle) {
        require(BlackListed[msg.sender] == false, "You have been blacklisted.");
        require(msg.value == price, "Insufficent funds");
        require(HandleClaimed[_Handle] == false, "Handle already claimed");
        
        accountAddressValid[msg.sender] = true;
        AccountIDs++;
        accountHandleToID[accountAddressToHandle[msg.sender] = accountIDToHandle[accountAddressToID[msg.sender] = AccountIDs] = _Handle] = accountAddressToID[msg.sender];
        accountHandleToAddress[_Handle] = msg.sender;
        HandleClaimed[_Handle] = true;
        _;
    }

    modifier ValidAccountPermissions () {
        require(BlackListed[msg.sender] == false, "You have been blacklisted.");
        require(accountAddressValid[msg.sender] == true, "An account is required for this functionality");
        
        _;
    }

    modifier ShippingDataWrittingPermissions() {
        require(ShippingDataWritePermissionsGranted[msg.sender] == true, "Tisk, tisk, tisk... You have no permissions");
        _;
    }

    modifier ValidListing (uint _GlobalSellPageID) {
        require(ListingExists[_GlobalSellPageID] == true, "Listing does not exist.");
        require(ListingPage[_GlobalSellPageID].Quantity > 0 && ListingPage[_GlobalSellPageID].OutOfStock == false, "Listing does not exist.");
        _;
    }

    //Report system
    struct GeneralPurposeVotingSystem {
        //Report Related
        string ReportTypeHumanReadable;
        uint ReportType;
        address AddressOfUserBehindContent; //Only for reporting people.
        uint ListingNumberToReport; //Only for posts.
        string ReportDetails;
        mapping(address => mapping(uint => mapping(bool => bool))) VerdictReached;
        //Moderator election related

        address PersonWhoWillBeElected;
        uint VoteType; //1 = vote in, 2 = vote out
        mapping(bool => bool) ElectionResult; //first bool represents if election result reached, second bool represents electionresult. 
        
    }
    
    //report elections

    //global voting.
    uint public ReportSessionNumber;
    mapping(uint => bool) ReportSessionNumberExists;
    mapping(uint => GeneralPurposeVotingSystem) public ReportTrialInstance;

    //Personal Voting.
    mapping(address => mapping(uint => mapping(bool => bool))) public UserHasvoted;
    
    //Catagorised voting
    mapping(uint => uint) NumberOfVotes;
    mapping(uint => mapping(bool => uint)) NumberOfVotesInSpecificCatagory;

    //Moderator elections
    //Maximum votes in moderator election.
    uint public constant MaximumModVotes = 25; //Must be changed prior to deployment.
    uint public constant ModVoteThreshHold = 13;

    //global voting.
    uint public ElectionSessionNumber;
    mapping(address => mapping(uint => mapping(uint => bool))) SpecificVoteSessionCreatedForPerson; //First uint represents vote type, second uint represents vote session number.
    mapping(address => mapping(uint => bool)) ElectionForPersonExists; //Determines if a person's election exists depending on context.
    mapping(address => uint) AddressToElectionNumber;
    mapping(uint => GeneralPurposeVotingSystem) public ElectionSessionInstance;

    //Personal Voting.
    mapping(address => mapping(uint => mapping(bool => bool))) public UserHasvotedInElection;
    
    //Catagorised voting
    mapping(uint => uint) NumberOfVotesInElection;
    mapping(uint => mapping(bool => uint)) NumberOfVotesYesOrNo; //First uint is election session number, bool is yes or no and third uint is number of votes that have specific bool value.

    //Voting session conclusion status.
    mapping(address => mapping(uint => mapping(bool => uint))) VoteSessionConcluded;
    
}


contract y is x{

    constructor(){
        AdminPermissions[msg.sender] = true;
    }

    function AddAdmins(uint _TypeOfPermission ,address _WhoToAdd, bool _Permission) public { //uint = 1 means granting data permissions, uint = 2 means granting 
        
        require(AdminPermissions[msg.sender] == true, "Permission denied.");

        if(_TypeOfPermission == 1) {

        DataWritePermissions[_WhoToAdd] = _Permission;

        } else if (_TypeOfPermission == 2){

        AdminPermissions[_WhoToAdd] = _Permission;

        }

    }

    //Join us
    function SignUp (string memory _Handle) payable public PriceToSignUp(_Handle) { //Creats an account

    }

    //Create listing

    function CreateListing (uint _Price, uint _ItemType, string memory _ListingName, uint _Quantity) public ValidAccountPermissions {

        //General rendering purposes.
        GlobalListingPageID++;
        SellPageTiedToAddress[GlobalListingPageID] = msg.sender;
        ItemID++;
        ListingPage[GlobalListingPageID].ItemID = ItemIDTiedToAddress[msg.sender] = ItemID;
        ListingPage[GlobalListingPageID].Price = _Price;
        require(_ItemType >= MaximumItemTypes, "Invalid item type.");
        ListingPage[GlobalListingPageID].ItemType = _ItemType;
        ListingPage[GlobalListingPageID].ListingName = _ListingName;
        ListingPage[GlobalListingPageID].Quantity = _Quantity;

        //Profile specific rendering purposes.
        PersonalListingNumber[msg.sender]++;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].ItemID = ItemIDTiedToAddress[msg.sender] = ItemID;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].Price = _Price;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].ItemType = _ItemType;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].ListingName = _ListingName;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].Quantity = _Quantity;

        //Determines escrow specific info.
        EscrowSessionTiedToListing[GlobalListingPageID] = GlobalListingPageID;
        BuyerOrSeller[msg.sender][GlobalListingPageID][true] = true;
        PersonViolatedEscrowTerms[msg.sender][GlobalListingPageID] = false;
        PersonEledgableForMoney[msg.sender][GlobalListingPageID] = 0;

        //Escrow number tied to listing.
        EscrowSessionTiedToListing[GlobalListingPageID] = GlobalListingPageID;

    }

    //Make orders
    function MakeOrder (uint _GlobalSellPageID, uint _Quantity) payable public ValidListing(_GlobalSellPageID) {
        
        require(ListingPage[_GlobalSellPageID].OutOfStock == false, "Item is out of stock.");
        require(msg.sender.balance >= ListingPage[_GlobalSellPageID].Price * _Quantity, "Balance to low for transaction.");
        require(msg.value == ListingPage[_GlobalSellPageID].Price * _Quantity, "Not enough money sent.");

        ListingPage[_GlobalSellPageID].Quantity--;

        if(ListingPage[_GlobalSellPageID].Quantity == 0){
            ListingPage[_GlobalSellPageID].OutOfStock = true;
        }

        ListingPage[_GlobalSellPageID].TransactionTime = block.timestamp;
        BuyerOrSeller[msg.sender][EscrowSessionTiedToListing[_GlobalSellPageID]][true] = false; //Not a seller duh
        
    }

    function Report (uint _TypeOfReport, uint _GlobalListingPageID, string memory _ReportDetails) public {

        require(ListingExists[_GlobalListingPageID] == true, "Listing you tried to report does not exist!");

        ReportSessionNumber++;
        ReportSessionNumberExists[ReportSessionNumber] = true;

        if(_TypeOfReport == 1) { //For reporting unrelated items.

            ReportTrialInstance[ReportSessionNumber].ReportTypeHumanReadable = "Reported for not being catagorically related";

        } else if (_TypeOfReport == 2){ //For reporting potentially illicit items.

            ReportTrialInstance[ReportSessionNumber].ReportTypeHumanReadable = "Reported for potentially being illicit.";

        } else if (_TypeOfReport == 3){ //For reporting potential scamers.

            ReportTrialInstance[ReportSessionNumber].ReportTypeHumanReadable = "Reported for scamming.";

        } 

        //Write info related to report trial instance!
        ReportTrialInstance[ReportSessionNumber].ReportType = _TypeOfReport;
        ReportTrialInstance[ReportSessionNumber].AddressOfUserBehindContent = SellPageTiedToAddress[_GlobalListingPageID];
        ReportTrialInstance[ReportSessionNumber].ListingNumberToReport = _GlobalListingPageID;
        ReportTrialInstance[ReportSessionNumber].ReportDetails = _ReportDetails;

        NumberOfVotes[ReportSessionNumber]++;

        //Write user specific data related to report trial instance.
        NumberOfVotesInSpecificCatagory[ReportSessionNumber][true] = NumberOfVotes[ReportSessionNumber];

        /* First bool represents if the 
        user voted, second bool represents what the user voted. */
        UserHasvoted[msg.sender][ReportSessionNumber][true] = true; 
        ReportSessionNumberExists[ReportSessionNumber] == true;

    }

     //Automated escrow system
    function WithdrawAutomatedEscrow(uint _GlobalSellPageID, uint _SellerOrBuyerCommand) public {

        require(BlackListed[msg.sender] == false, "Can't whilst blacklisted.");

        if (_SellerOrBuyerCommand == 1) { //Buyer commands
            
            require(BuyerOrSeller[msg.sender][_GlobalSellPageID][true] == false, "You are not a buyer");

            Report(3,_GlobalSellPageID,"Item is not what I wanted to buy.");

        } else if (_SellerOrBuyerCommand == 2) { //Seller commands

            require(BuyerOrSeller[msg.sender][_GlobalSellPageID][true] == true, "You are not a seller");
            require(ListingPage[GlobalListingPageID].TransactionTime == ListingPage[_GlobalSellPageID].TransactionTime + Escrowithdrawtime, "Must wait 1 week before withdrawing money");

            payable (msg.sender).call{value: ListingPage[GlobalListingPageID].Price}("");

        }

    }

    //Report Trial to determine guilt or innocence of perp
    function VotigSystem (uint _VoteType, uint _ReportSessionNumber, bool _Vote, address _WhoToVoteFor, uint _TypeOfVote) public { //Vote type 1 = Report system, Vote type 2 is for voting in or out somoene

        if(_VoteType == 1) {

        require(NumberOfVotes[ReportSessionNumber] <= MaxVotes, "Maximum votes have been reached for this topic.");
        require(ReportSessionNumberExists[_ReportSessionNumber] == true, "Invalid report session number");
        require(UserHasvoted[msg.sender][_ReportSessionNumber][false] , "You already voted.");
        
        NumberOfVotes[ReportSessionNumber]++;

        if(ReportTrialInstance[ReportSessionNumber].ReportType == 1) { //Minor offense report!
            
            UserHasvoted[msg.sender][_ReportSessionNumber][true] = _Vote;
            NumberOfVotesInSpecificCatagory[ReportSessionNumber][_Vote] = NumberOfVotes[ReportSessionNumber];

            if(NumberOfVotesInSpecificCatagory[ReportSessionNumber][_Vote] >= VoteThreshhold){
                
                GuiltAccumalated[ReportTrialInstance[ReportSessionNumber].AddressOfUserBehindContent]++;

                if(GuiltAccumalated[ReportTrialInstance[ReportSessionNumber].AddressOfUserBehindContent] >= MaximumGuiltCountPriorToBlaccklisting){
                    
                    BlackListed[ReportTrialInstance[ReportSessionNumber].AddressOfUserBehindContent] = true;

                }

            }

        } else if (ReportTrialInstance[ReportSessionNumber].ReportType == 2) { //Majour offense report!

            UserHasvoted[msg.sender][_ReportSessionNumber][true] = _Vote;
            NumberOfVotesInSpecificCatagory[ReportSessionNumber][_Vote] = NumberOfVotes[ReportSessionNumber];


            if(NumberOfVotesInSpecificCatagory[ReportSessionNumber][_Vote] >= VoteThreshhold){
                
                BlackListed[ReportTrialInstance[ReportSessionNumber].AddressOfUserBehindContent] = true;

            } 

        } else if (ReportTrialInstance[ReportSessionNumber].ReportType == 3) { //Scam Report!

            UserHasvoted[msg.sender][_ReportSessionNumber][true] = _Vote;
            NumberOfVotesInSpecificCatagory[ReportSessionNumber][_Vote] = NumberOfVotes[ReportSessionNumber];


            if(NumberOfVotesInSpecificCatagory[ReportSessionNumber][_Vote] >= VoteThreshhold){
                
                BlackListed[ReportTrialInstance[ReportSessionNumber].AddressOfUserBehindContent] = true;

            } 

        }

        } else if (_VoteType == 2) {

        require(BlackListed[_WhoToVoteFor] == false, "Cannot vote in black listed people");
        require(accountAddressValid[_WhoToVoteFor] == true, "Person you vote in must have an account.");
        require(UserHasvotedInElection[msg.sender][AddressToElectionNumber[_WhoToVoteFor]][true] == true || UserHasvotedInElection[msg.sender][AddressToElectionNumber[_WhoToVoteFor]][true] == false, "You have already voted");
        require(NumberOfVotesInElection[AddressToElectionNumber[_WhoToVoteFor]] == MaximumModVotes, "Election concluded");
        require(SpecificVoteSessionCreatedForPerson[_WhoToVoteFor][AddressToElectionNumber[_WhoToVoteFor]][_TypeOfVote] == false, "Election already created.");

        if(_TypeOfVote == 1) { //vote in

            if(SpecificVoteSessionCreatedForPerson[_WhoToVoteFor][ElectionSessionNumber][_TypeOfVote] == false) {

                ElectionSessionNumber++;
                SpecificVoteSessionCreatedForPerson[_WhoToVoteFor][ElectionSessionNumber][_TypeOfVote] = true;
                ElectionForPersonExists[_WhoToVoteFor][1] = true;
                AddressToElectionNumber[_WhoToVoteFor] = ElectionSessionNumber; 

            }
            
            UserHasvotedInElection[msg.sender][AddressToElectionNumber[_WhoToVoteFor]][true] == true;
            NumberOfVotesInElection[AddressToElectionNumber[_WhoToVoteFor]]++;
            NumberOfVotesYesOrNo[AddressToElectionNumber[_WhoToVoteFor]][true]++;
            
            if(NumberOfVotesYesOrNo[AddressToElectionNumber[_WhoToVoteFor]][true] >= ModVoteThreshHold){

                ModeratorPermissions[_WhoToVoteFor] = true;
                ElectionSessionInstance[AddressToElectionNumber[_WhoToVoteFor]].PersonWhoWillBeElected = _WhoToVoteFor;
                SpecificVoteSessionCreatedForPerson[_WhoToVoteFor][ElectionSessionNumber][_TypeOfVote] = true;
                ElectionSessionInstance[AddressToElectionNumber[_WhoToVoteFor]].VoteType = _TypeOfVote;
                ElectionSessionInstance[AddressToElectionNumber[_WhoToVoteFor]].ElectionResult[true] = true;

                SpecificVoteSessionCreatedForPerson[_WhoToVoteFor][AddressToElectionNumber[_WhoToVoteFor]][_TypeOfVote] == false;
            }

        } else if (_TypeOfVote == 2) { //vote out

            if(SpecificVoteSessionCreatedForPerson[_WhoToVoteFor][ElectionSessionNumber][_TypeOfVote] == false) {

                ElectionSessionNumber++;
                SpecificVoteSessionCreatedForPerson[_WhoToVoteFor][ElectionSessionNumber][_TypeOfVote] = true;
                ElectionForPersonExists[_WhoToVoteFor][2] = false;
                AddressToElectionNumber[_WhoToVoteFor] = ElectionSessionNumber; 

            }
            
            UserHasvotedInElection[msg.sender][AddressToElectionNumber[_WhoToVoteFor]][true] == false;
            NumberOfVotesInElection[AddressToElectionNumber[_WhoToVoteFor]]++;
            NumberOfVotesYesOrNo[AddressToElectionNumber[_WhoToVoteFor]][false]++;
            
            if(NumberOfVotesYesOrNo[AddressToElectionNumber[_WhoToVoteFor]][false] >= ModVoteThreshHold){

                ModeratorPermissions[_WhoToVoteFor] = false;
                ElectionSessionInstance[AddressToElectionNumber[_WhoToVoteFor]].PersonWhoWillBeElected = _WhoToVoteFor;
                SpecificVoteSessionCreatedForPerson[_WhoToVoteFor][ElectionSessionNumber][_TypeOfVote] = true;
                ElectionSessionInstance[AddressToElectionNumber[_WhoToVoteFor]].VoteType = _TypeOfVote;
                ElectionSessionInstance[AddressToElectionNumber[_WhoToVoteFor]].ElectionResult[true] = false;
                
                SpecificVoteSessionCreatedForPerson[_WhoToVoteFor][AddressToElectionNumber[_WhoToVoteFor]][_TypeOfVote] == false;

            }

        }

        } 

    }


    function SpecialActionsPanel (uint _ListingToInfluence , address _PersonToInfluence, bool _BoolData, bool _BoolData2, uint _IntData) public {

        require(BlackListed[msg.sender] == false, "You have been blacklisted.");

        if(ModeratorPermissions[msg.sender] == true) {

        assert(ModeratorPermissions[msg.sender] == true);
        
        BlackListed[_PersonToInfluence] = _BoolData;

        } else if (DataWritePermissions[msg.sender] == true) {

        assert(DataWritePermissions[msg.sender] == true);

        PersonalListingPage[SellPageTiedToAddress[_ListingToInfluence]][_ListingToInfluence].ItemIDofShippment[_PersonToInfluence] = ListingPage[_ListingToInfluence].ItemIDofShippment[_PersonToInfluence] = ListingPage[_ListingToInfluence].ItemID;
        PersonalListingPage[SellPageTiedToAddress[_ListingToInfluence]][_ListingToInfluence].QuantityofShippment[_PersonToInfluence] = ListingPage[_ListingToInfluence].QuantityofShippment[_PersonToInfluence] = _IntData;
        PersonalListingPage[SellPageTiedToAddress[_ListingToInfluence]][_ListingToInfluence].ShipmentStarted[_PersonToInfluence] = ListingPage[_ListingToInfluence].ShipmentStarted[_PersonToInfluence] = _BoolData;
        PersonalListingPage[SellPageTiedToAddress[_ListingToInfluence]][_ListingToInfluence].Recieved[_PersonToInfluence] = ListingPage[_ListingToInfluence].Recieved[_PersonToInfluence] = _BoolData2;
        
        }

    }

}
