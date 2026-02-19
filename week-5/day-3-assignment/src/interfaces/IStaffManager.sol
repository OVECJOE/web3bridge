// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IStaffManager {
    event StaffAdded(address indexed staffAddress, string name, string position);
    event StaffRemoved(address indexed staffAddress);
    event SalaryUpdated(address indexed staffAddress, uint256 newSalary, address tokenAddress);

    function addStaff(address _staffAddress, string memory _name, string memory _position, uint256 _salary, address _salaryToken) external;
    function removeStaff(address _staffAddress) external;
    function updateSalary(address _staffAddress, uint256 _newSalary, address _tokenAddress) external;
    function getStaffDetails(address _staffAddress) external view returns (string memory name, string memory position, uint256 salary, address salaryToken);
    function paySalary(address _staffAddress) external returns (bool);
}
