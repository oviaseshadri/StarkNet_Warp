// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//import "@openzeppelin/contracts/access/Ownable.sol";

interface Inftcontract{
    function safeMint(address to, string memory uri) external;

}
contract Shine{//is Ownable 
    struct Post {
        uint256 id;
        bool isPublic;
        address creatorAddress;
        string postName;
        string postDescription;
        string image;
    }

    struct Subscription {
        uint256 expiryTimestamp;
        uint256 amount;
        address userAddress;
        address creatorAddress;
    }

    struct User {
        uint256 id;
        uint256 amount;
        address userAddress;
        string username;
        string description;
        address[] subscribers;
        string image;
    }

    Post[] public posts;
    User[] public users;
    Subscription[] public subscriptions;
    address public nftcontractaddress;

    // function setnftcontractaddress(address _nftcontractaddress)external onlyOwner {
    //      nftcontractaddress = _nftcontractaddress;
    // }

    function postsCount() public view returns (uint256) {
        return posts.length;
    }

    function creatorsCount() public view returns (uint256) {
        return users.length;
    }

    function getUserDetails(address _userAddress)
        public
        view
        returns (User memory)
    {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].userAddress == _userAddress) {
                return users[i];
            }
        }
    }

    function isRegisteredUser(address _user) public view returns (bool) {
        bool registeredUser;
        for (uint256 i = 0; i < users.length; ++i) {
            if (users[i].userAddress == _user) {
                registeredUser = true;
            }
        }
        return registeredUser;
    }

    function getSubscriptions() external view returns (Subscription[] memory) {
        uint256 j = 0;
        for (uint256 i = 0; i < subscriptions.length; i++) {
            if (subscriptions[i].userAddress == msg.sender) {
                j++;
            }
        }
        Subscription[] memory _subscriptions = new Subscription[](j);
        j = 0;
        for (uint256 i = 0; i < subscriptions.length; i++) {
            if (subscriptions[i].userAddress == msg.sender) {
                _subscriptions[j] = subscriptions[i];
                j++;
            }
        }
        return _subscriptions;
    }

    function getPosts() external view returns (Post[] memory) {
        uint256 j = 0;
        for (uint256 i = 0; i < posts.length; i++) {
            bool flag = false;
            for (uint256 k = 0; k < subscriptions.length; k++) {
                if (
                    subscriptions[k].userAddress == msg.sender &&
                    posts[i].creatorAddress == subscriptions[k].creatorAddress
                ) {
                    flag = true;
                }
            }
            if (flag || posts[i].isPublic) {
                j++;
            }
        }
        Post[] memory _posts = new Post[](j);
        j = 0;
        for (uint256 i = 0; i < posts.length; i++) {
            bool flag = false;
            for (uint256 k = 0; k < subscriptions.length; k++) {
                if (
                    subscriptions[k].userAddress == msg.sender &&
                    posts[i].creatorAddress == subscriptions[k].creatorAddress
                ) {
                    flag = true;
                }
            }
            if (flag || posts[i].isPublic) {
                _posts[j] = posts[i];
                j++;
            }
        }
        return _posts;
    }

    function getCreatorData(address _creatorAddress)
        external
        view
        returns (Post[] memory, User memory)
    {
        uint256 j = 0;
        for (uint256 i = 0; i < posts.length; i++) {
            if (posts[i].creatorAddress == _creatorAddress) {
                bool flag = false;
                for (uint256 k = 0; k < subscriptions.length; k++) {
                    if (
                        subscriptions[k].userAddress == msg.sender &&
                        posts[i].creatorAddress ==
                        subscriptions[k].creatorAddress
                    ) {
                        flag = true;
                    }
                }
                if (
                    flag || posts[i].isPublic || _creatorAddress == msg.sender
                ) {
                    j++;
                }
            }
        }
        Post[] memory _posts = new Post[](j);
        j = 0;
        for (uint256 i = 0; i < posts.length; i++) {
            if (posts[i].creatorAddress == _creatorAddress) {
                bool flag = false;
                for (uint256 k = 0; k < subscriptions.length; k++) {
                    if (
                        subscriptions[k].userAddress == msg.sender &&
                        posts[i].creatorAddress ==
                        subscriptions[k].creatorAddress
                    ) {
                        flag = true;
                    }
                }
                if (
                    flag || posts[i].isPublic || _creatorAddress == msg.sender
                ) {
                    _posts[j] = posts[i];
                    j++;
                }
            }
        }
        User memory user;
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].userAddress == _creatorAddress) {
                user = users[i];
            }
        }
        return (_posts, user);
    }

    function createUser(
        string memory _username,
        string memory _description,
        string memory _image
    ) external {
        User memory user;
        user.id = users.length;
        user.amount = 1 ether;
        user.userAddress = msg.sender;
        user.username = _username;
        user.description = _description;
        user.image = _image;
        users.push(user);
    }

    function createPost(
        string memory _postName,
        string memory _postDescription,
        string memory _image
    ) external {
        posts.push(
            Post(
                posts.length,
                false,
                msg.sender,
                _postName,
                _postDescription,
                _image
            )
        );
    }

    function updatePost(
        uint256 _id,
        string memory _postName,
        string memory _postDescription
    ) external {
        require(msg.sender == posts[_id].creatorAddress);
        posts[_id].postName = _postName;
        posts[_id].postDescription = _postDescription;
    }

    function subscribeToCreator(uint256 _id, uint256 _expiryTimestamp)
        external
        payable
    {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                users[i].subscribers.push(msg.sender);
                require(msg.value >= users[i].amount);
                payable(users[i].userAddress).transfer(msg.value);
                subscriptions.push(
                    Subscription(
                        _expiryTimestamp,
                        users[i].amount,
                        msg.sender,
                        users[i].userAddress
                    )
                );
                break;
            }
        }
    }

    function renewSubscription(uint256 _id, uint256 _expiryTimestamp)
        external
        payable
    {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                for (uint256 j = 0; j < subscriptions.length; j++) {
                    if (
                        subscriptions[j].userAddress == msg.sender &&
                        subscriptions[j].creatorAddress == users[i].userAddress
                    ) {
                        subscriptions[j].expiryTimestamp = _expiryTimestamp;
                        require(msg.value >= users[i].amount);
                        payable(users[i].userAddress).transfer(msg.value);
                        break;
                    }
                }
                break;
            }
        }
    }

    function mintNFT(address To, string memory URI) external{
    Inftcontract(nftcontractaddress).safeMint(To, URI);
    }
}
