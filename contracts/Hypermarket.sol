// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Hypermarket {
    struct Product {
        string name;
        uint256 price;
        address owner;
        uint256 registered;
    }
    struct Debt {
        uint256 pending;
        uint256 current;
    }
    mapping(uint256 => Product) private _products;
    mapping(address => mapping(uint256 => uint256)) private _supplies;
    mapping(address => mapping(address => mapping(uint256 => Debt))) private _debts;
    uint256 private _counter;
    bool private _lock;

    modifier ReentrencyGuard() {
        require(_lock == false, "Hypermarket: reentrency detected");
        _lock = true;
        _;
        _lock = false;
    }

    function newProduct(string memory name, uint256 price) public {
        _counter++;
        _products[_counter] = Product({name: name, price: price, owner: msg.sender, registered: block.timestamp});
    }

    function fillProduct(uint256 id, uint256 amount) public {
        require(msg.sender == product(id).owner, "Hypermarket: cannot fill product of other user");
        _supplies[msg.sender][id] += amount;
    }

    function buyProduct(uint256 id, uint256 amount) public payable ReentrencyGuard {
        require(supplyOwner(id) > 0, "Hypermarket: supply empty for this product");
        address receiver = product(id).owner;
        _supplies[receiver][id] -= amount;
        _supplies[msg.sender][id] += amount;
        payable(receiver).transfer(product(id).price * amount);
    }

    function exchangeProduct(uint256 id, uint256 amount) public {
        require(supplyOf(msg.sender, id) > 0, "Hypermarket: user supply empty for this product");
        _supplies[msg.sender][id] -= amount;
    }

    function giveProduct(
        address account,
        uint256 id,
        uint256 amount
    ) public {
        exchangeProduct(id, amount);
        _supplies[account][id] -= amount;
    }

    function lendProduct(
        address account,
        uint256 id,
        uint256 amount
    ) public {
        _debts[msg.sender][account][id].pending += amount;
    }

    function acceptProduct(address account, uint256 id) public {
        uint256 amount = pendingDebt(account, msg.sender, id);
        require(amount > 0, "Hypermarket: account do not have lend this product to user");
        _debts[account][msg.sender][id].current += amount;
        _debts[account][msg.sender][id].pending -= amount;
        giveProduct(account, id, amount);
    }

    function repayProduct(
        address account,
        uint256 id,
        uint256 amount
    ) public {
        giveProduct(account, id, amount);
        _debts[account][msg.sender][id].current -= amount;
    }

    function product(uint256 id) public view returns (Product memory) {
        return _products[id];
    }

    function supplyOf(address account, uint256 id) public view returns (uint256) {
        return _supplies[account][id];
    }

    function supplyOwner(uint256 id) public view returns (uint256) {
        return _supplies[product(id).owner][id];
    }

    function pendingDebt(
        address lender,
        address borrower,
        uint256 id
    ) public view returns (uint256) {
        return _debts[lender][borrower][id].pending;
    }

    function currentDebt(
        address lender,
        address borrower,
        uint256 id
    ) public view returns (uint256) {
        return _debts[lender][borrower][id].current;
    }

    function counter() public view returns (uint256) {
        return _counter;
    }
}
