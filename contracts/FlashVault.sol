pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// import "./interfaces/IERC20.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";

// deployed at 0x5C3ff0B8AF2c0b27c06294eEb58032E9b291C71A

contract FlashVault is ERC20,IERC3156FlashLender,ReentrancyGuard,Ownable,Pausable{
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    using SafeMath for uint256;
    IERC20 public target;
    uint256 public fee = 1;// 0.01%
    uint8 public deci;

    constructor(string memory name, string memory symbol,IERC20 _target,uint8 _deci,uint256 _fee) ERC20(name, symbol){
        target = _target;
        fee = _fee;
        deci = _deci;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }

    function decimals() public view override returns (uint8) {
        return deci;
    }

    // Enter the bar. Pay some targets. Earn some shares.
    function enter(uint256 _amount) public nonReentrant whenNotPaused {
        uint256 totaltarget = target.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totaltarget == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totaltarget);
            _mint(msg.sender, what);
        }
        target.transferFrom(msg.sender, address(this), _amount);
    }
    

    // Leave the bar. Claim back your targets.
    function leave(uint256 _share) public nonReentrant whenNotPaused {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(target.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        target.transfer(msg.sender, what);
    }
    

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant whenNotPaused returns(bool) {
        require(
            token==address(target),
            "FlashLender: Unsupported currency"
        );
        uint256 _fee = _flashFee(token, amount);
        require(
            IERC20(token).transfer(address(receiver), amount),
            "FlashLender: Transfer failed"
        );
        require(
            receiver.onFlashLoan(msg.sender, token, amount, _fee, data) == CALLBACK_SUCCESS,
            "FlashLender: Callback failed"
        );
        require(
            IERC20(token).transferFrom(address(receiver), address(this), amount + _fee),
            "FlashLender: Repay failed"
        );
        return true;
    }
    function flashFee(
        address token,
        uint256 amount
    ) external view override returns (uint256) {
        require(
            token==address(target),
            "FlashLender: Unsupported currency"
        );
        return _flashFee(token, amount);
    }

    /**
     * @dev The fee to be charged for a given loan. Internal function with no checks.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        return amount * fee / 10000;
    }

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view override returns (uint256) {
        return (token==address(target)) ? IERC20(token).balanceOf(address(this)) : 0;
    }

}