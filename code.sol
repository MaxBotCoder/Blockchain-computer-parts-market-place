//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract x {

    mapping(address => bool) public AdminPermissions;
    mapping(address => bool) public DataWritePermissions;

    uint public constant price = 4;

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

    //Person eledgable for money.
    uint public AutomatedEscrowSessionNumber;
    mapping(address => mapping(uint => mapping(bool => bool))) BuyerOrSeller; //Bool 1 determines if person is involved with transaction bool 2 determines if person is buyer or seller. 
    mapping(address => mapping(uint => bool)) PersonViolatedEscrowTerms;
    mapping(address => mapping(uint => uint)) PersonEledgableForMoney;


    //Listing info
    struct Listing {
        uint ItemID;
        uint Price;
        uint ItemType;
        string ListingName;
        string About;
        uint Quantity;
        bool OutOfStock;
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

    //Shipping info
    struct ShippingInfo {
        uint ItemID;
        uint Quantity;
        bool ShipmentStarted;
        bool Recieved;
    }

    //Shipping Info
    uint public ShipmentID;
    mapping(uint => ShippingInfo) public ViewShippingInfo;

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
    struct ReportTrialStorage {
        string ReportTypeHumanReadable;
        uint ReportType;
        address AddressOfUserBehindContent; //Only for reporting people.
        uint ListingNumberToReport; //Only for posts.
        string ReportDetails;
        mapping(address => mapping(uint => mapping(bool => bool))) VerdictReached;
    }
    
    //global voting.
    uint public ReportSessionNumber;
    mapping(uint => bool) ReportSessionNumberExists;
    mapping(uint => ReportTrialStorage) public ReportTrialInstance;

    //Personal Voting.
    mapping(address => mapping(uint => mapping(bool => bool))) public UserHasvoted;
    
    //Catagorised voting
    mapping(uint => uint) NumberOfVotes;
    mapping(uint => mapping(bool => uint)) NumberOfVotesInSpecificCatagory;
    
}

contract y is x{

    //Join us

    function SignUp (string memory _Handle) payable public PriceToSignUp(_Handle) { //Creats an account

    }

    //Create listing

    function CreateListing (uint _Price, uint _ItemType, string memory _ListingName, string memory _About, uint _Quantity) public ValidAccountPermissions {

        //General rendering purposes.
        GlobalListingPageID++;
        SellPageTiedToAddress[GlobalListingPageID] = msg.sender;
        ItemID++;
        ListingPage[GlobalListingPageID].ItemID = ItemIDTiedToAddress[msg.sender] = ItemID;
        ListingPage[GlobalListingPageID].Price = _Price;
        require(_ItemType >= MaximumItemTypes, "Invalid item type.");
        ListingPage[GlobalListingPageID].ItemType = _ItemType;
        ListingPage[GlobalListingPageID].ListingName = _ListingName;
        ListingPage[GlobalListingPageID].About = _About;
        ListingPage[GlobalListingPageID].Quantity = _Quantity;

        //Profile specific rendering purposes.
        PersonalListingNumber[msg.sender]++;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].ItemID = ItemIDTiedToAddress[msg.sender] = ItemID;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].Price = _Price;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].ItemType = _ItemType;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].ListingName = _ListingName;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].About = _About;
        PersonalListingPage[msg.sender][PersonalListingNumber[msg.sender]].Quantity = _Quantity;

        //Determines escrow specific info.
        BuyerOrSeller[msg.sender][GlobalListingPageID][true] = true;
        

    }

    //Make orders
    function MakeOrder (uint _GlobalSellPageID, uint _Quantity) payable public ValidListing(_GlobalSellPageID) {
        
        require(ListingPage[_GlobalSellPageID].OutOfStock == false, "Item is out of stock.");
        require(msg.sender.balance >= ListingPage[_GlobalSellPageID].Price * _Quantity, "Balance to low for transaction.");
        require(msg.value == ListingPage[_GlobalSellPageID].Price * _Quantity, "Now enough money was sent to complete this transaction tisk... tisk...");

        ListingPage[_GlobalSellPageID].Quantity--;

        if(ListingPage[_GlobalSellPageID].Quantity == 0){
            ListingPage[_GlobalSellPageID].OutOfStock = true;
        }

        AutomatedEscrowSessionNumber++;


    }

    //Automated escrow system
    function WithdrawAutomatedEscrow() public payable  {

        

    }

    function Report (uint _TypeOfReport, uint _GlobalListingPageID, string memory _ReportDetails) public {

        require(ListingExists[_GlobalListingPageID] == true, "Listing you tried to report does not exist!");
        require(_TypeOfReport == 1 || _TypeOfReport == 2, "Invalid report type.");

        ReportSessionNumber++;
        ReportSessionNumberExists[ReportSessionNumber] = true;

        if(_TypeOfReport == 1) { //For reporting unrelated items.

             ReportTrialInstance[ReportSessionNumber].ReportTypeHumanReadable = "Reported for not being catagorically related";

        } else if (_TypeOfReport == 2){ //For reporting potentially illicit items.

            ReportTrialInstance[ReportSessionNumber].ReportTypeHumanReadable = "Reported for potentially being illicit.";

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

    function ReportTrial (uint _ReportSessionNumber, bool _Vote) public {

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

           
        } 

    }

    function ModeratorQuickActionPanel (uint _ReportSession, bool _BanStatus) public {

    }

}
