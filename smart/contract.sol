// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
 
contract Ownable
{
    address owner;
 
    constructor()
    {
        owner = msg.sender;
    }
 
    modifier OnlyOwner()
    {
        require(owner == msg.sender, "Only owner can run this function!");
        _;
    }
}
 
contract Employable is Ownable
{
    constructor() Ownable()
    {}
    mapping(address=>mapping(address=>bool)) shop_employees;
    mapping(address=>address) employee_shop;
 
    modifier OnlyEmployee(address empl)
    {
        address shop = employee_shop[empl];
        require(shop_employees[shop][empl]==true, "Only Employee can run this function!");
        _;
    }
 
    function _AddEmployee(address shop, address employee) internal
    {
        shop_employees[shop][employee] = true;
        employee_shop[employee] = shop;
    }
 
    function AddEmployee(address employee) public OnlyEmployee(msg.sender)
    {
        _AddEmployee(employee_shop[msg.sender], employee);
    }
}
 
contract MarketPlace is Employable
{
    enum Status {None, Sold, Rejected, Returned, Canceled}
 
    event Deployed (uint unit_length);
 
    struct Shop
    {
        string name;
        string city;
        address payable account;
        bool created;
    }
 
    struct Item
    {
        string name;
        uint unit;
        uint256 price;
        uint amount;
        uint def_amount;
        uint[] grades;
       
    }
 
    struct Purchase
    {
        address payable customer;
        address shop;
        string shop_name;
        uint item_index;
        string item_name;
        uint amount;
        uint price;
        Status status;
    }
 
    string[] units;
 
    address[] shops_account;
    mapping(address=>Shop) shops;
    mapping(address=>Item[]) items;
    mapping(address=>Purchase[]) purchases;
    //Purchase[] rejects;
    mapping(address=>Purchase[]) customer_rejects;
    mapping(address=>Purchase[]) shop_rejects;
 
    constructor() Employable()
    {
        units.push(unicode"шт");
        units.push(unicode"кг");
        units.push(unicode"л");
        units.push(unicode"м");
        emit Deployed(units.length);
    }
 
    function AddUnit(string memory shops_unit) OnlyOwner public
    {
        units.push(shops_unit);
    }
 
    function GetUnits() public view returns(string[] memory)
    {
        return units;
    }
   
    function GetShops() public view returns(Shop[] memory)
    {
        Shop[] memory temp = new Shop[](shops_account.length);
        for(uint i=0;i < shops_account.length;i++)
            temp[i] = shops[shops_account[i]];
        return temp;
    }
 
    function GetEmployeeShop() OnlyEmployee(msg.sender) public view returns(address)
    {
        return employee_shop[msg.sender];
    }
 
    function GetItems(address shop_account) public view returns(Item[] memory)
    {
        return items[shop_account];
    }
 
    function AddItem(string memory name, uint unit, uint256 price, uint amount) OnlyEmployee(msg.sender) public
    {
        require(unit >= 0 && unit < units.length, "Wrong unit!");
        address shop = employee_shop[msg.sender];
 
        Item memory item;
        item.name = name;
        item.unit = unit;
        item.price = price;
        item.amount = amount;
        item.def_amount = 0;
        items[shop].push(item);
    }
 
    function AddShop(string memory name, string memory city, address payable acc, address employee) OnlyOwner public
    {
        require(!shops[acc].created, "This shop already exists!");
        require(employee_shop[employee] == address(0), "Employee already has been employed!");
        Shop memory shop;
        shop.name = name;
        shop.city = city;
        shop.account = acc;
        shop.created = true;
 
        shops[acc] = shop;
        shops_account.push(acc);
       
        _AddEmployee(acc, employee);
    }
 
    function BuyItem(address shop, uint item_index, uint amount) public payable
    {
        require(shops[shop].created == true, "There is no such shop!");
        require(item_index >= 0 && item_index < items[shop].length, "There is no such item in this shop!");
        require(msg.value == items[shop][item_index].price * amount, "Not enough ether!");
        require(items[shop][item_index].amount > amount, "Not enough item amount!");
 
        items[shop][item_index].amount-= amount;
        shops[shop].account.transfer(msg.value);
 
        purchases[msg.sender].push(Purchase({customer: payable(msg.sender), shop: shop, shop_name: shops[shop].name, item_index: item_index, item_name: items[shop][item_index].name, amount: amount, price: items[shop][item_index].price, status: Status.Sold}));
    }
 
    function GradeItem(address shop, uint item_index, uint grade) public
    {
        require(shops[shop].created == true, "There is no such shop!");
        require(item_index >= 0 && item_index < items[shop].length, "There is no such item in this shop!");
        require(grade >= 1 && grade <= 5, "Wrong grade!");
 
        items[shop][item_index].grades.push(grade);
    }
 
    function GetMyPurchases() public view  returns(Purchase[] memory)
    {
        return purchases[msg.sender];
    }
 
    function RejectPurchase(uint index) public
    {
        require(index >= 0 && index < purchases[msg.sender].length, "Index out of range!");
        require(purchases[msg.sender][index].status == Status.Sold, "There is no such purchase!");
 
        /////// Transfer Purchase to Rejects///////////////
        Purchase memory p = purchases[msg.sender][index];
        p.status = Status.Rejected;
        shop_rejects[p.shop].push(p);
        customer_rejects[msg.sender].push(p);
    }
 
    function GetMyRejects()public view returns(Purchase[] memory)
    {
        return customer_rejects[msg.sender];
    }
 
    function GetShopRejects() OnlyEmployee(msg.sender) public view returns(Purchase[] memory)
    {
        address shop = employee_shop[msg.sender];
        return shop_rejects[shop];
    }
 
    function ChangeCustomerPurchaseStatus(address account, address shop, uint item_index, Status status) internal
    {
        for(uint i=0;i<customer_rejects[account].length;i++)
        {
            if(customer_rejects[account][i].shop == shop &&
            customer_rejects[account][i].item_index == item_index &&
            customer_rejects[account][i].status == Status.Rejected)
            {
                customer_rejects[account][i].status = status;
                break;
            }
        }
    }
 
    function ProcessReject(uint reject_index) OnlyEmployee(msg.sender) public payable
    {
        address shop = employee_shop[msg.sender];
        require(reject_index >= 0 && reject_index < shop_rejects[shop].length, "Index out of range!");
        require(shop_rejects[shop][reject_index].status != Status.Returned &&
                shop_rejects[shop][reject_index].status != Status.Canceled, "This reject was processed!");
       
        uint index = shop_rejects[shop][reject_index].item_index;
        require(msg.value == shop_rejects[shop][reject_index].price * shop_rejects[shop][reject_index].amount, "Not enough funding!");
       
        shop_rejects[shop][reject_index].status = Status.Returned;
        items[shop][index].def_amount++;
        //return money
        shop_rejects[shop][reject_index].customer.transfer(msg.value);
        //change customer reject status
        address cust_acc = shop_rejects[shop][reject_index].customer;
        ChangeCustomerPurchaseStatus(cust_acc, shop, index, Status.Returned);
    }
 
    function CancelReject(uint reject_index) public OnlyEmployee(msg.sender)
    {
        address shop = employee_shop[msg.sender];
        require(reject_index >= 0 && reject_index < shop_rejects[shop].length, "Index out of range!");
        require(shop_rejects[shop][reject_index].status != Status.Returned &&
                shop_rejects[shop][reject_index].status != Status.Canceled, "This reject was processed!");
       
        shop_rejects[shop][reject_index].status = Status.Canceled;
        address cust_acc = shop_rejects[shop][reject_index].customer;
        ChangeCustomerPurchaseStatus(cust_acc, shop, shop_rejects[shop][reject_index].item_index, Status.Canceled);
    }
}