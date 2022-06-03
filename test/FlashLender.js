const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

const provider = waffle.provider;

describe("FlashBorrower", function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.deployer = this.signers[0]
    this.user1 = this.signers[1]

    this.FlashVault = await ethers.getContractFactory("FlashVault");
    this.ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    this.FlashBorrower = await ethers.getContractFactory("FlashBorrower");
  });
  beforeEach(async function () {
    this.weth = await this.ERC20Mock.deploy("WETH", "WETH");
    await this.weth.deployed();
    this.dai = await this.ERC20Mock.deploy("DAI", "DAI");
    await this.dai.deployed();
    this.lender = await this.FlashVault.deploy("Peppermint Loaned MINTME","xMINTME",this.weth.address,await this.weth.decimals(), 10);
    await this.lender.deployed();
    this.borrower = await this.FlashBorrower.deploy(this.lender.address);
    await this.borrower.deployed();


    // await this.weth.mint(this.lender.address, 1000);
    // await this.dai.mint(this.lender.address, 999);
    await this.weth.mint(this.deployer.address, 1000);
    await this.weth.approve(this.lender.address, 1000);

    await this.lender.enter(1000);

    console.log(await this.weth.balanceOf(this.lender.address))
    
  });
  it('should do a simple flash loan',async function() {

    await this.borrower.connect(this.user1).flashBorrow(this.weth.address, 1)

    let balanceAfter = await this.weth.balanceOf(this.user1.address)
    expect(balanceAfter.toString()).to.equal('0');
    let flashBalance = await this.borrower.flashBalance();
    expect(flashBalance.toString()).to.equal('1');
    let flashToken = await this.borrower.flashToken();
    expect(flashToken.toString()).to.equal(this.weth.address);
    let flashAmount = await this.borrower.flashAmount();
    expect(flashAmount.toString()).to.equal('1');
    let flashInitiator = await this.borrower.flashInitiator();
    expect(flashInitiator.toString()).to.equal(this.borrower.address);

    

    // await this.borrower.connect(this.user1).flashBorrow(this.dai.address, 3)

    // let balanceAfter2 = await this.dai.balanceOf(this.user1.address)
    // expect(balanceAfter2.toString()).to.equal('0');
    // let flashBalance2 = await this.borrower.flashBalance();
    // expect(flashBalance2.toString()).to.equal('3');
    // let flashToken2 = await this.borrower.flashToken();
    // expect(flashToken2.toString()).to.equal(this.dai.address);
    // let flashAmount2 = await this.borrower.flashAmount();
    // expect(flashAmount2.toString()).to.equal('3');
    // let flashInitiator2 = await this.borrower.flashInitiator();
    // expect(flashInitiator2.toString()).to.equal(this.borrower.address);

  });
    it('should do a loan that pays fees', async function() {

      const loan = 1000;
      const fee = await this.lender.flashFee(this.weth.address,loan);

      await this.weth.connect(this.user1).mint(this.borrower.address,1);

      await this.borrower.connect(this.user1).flashBorrow(this.weth.address, loan);

      let balanceAfter = await this.weth.balanceOf(this.user1.address)
      expect(balanceAfter.toString()).to.equal('0');
      let flashBalance = await this.borrower.flashBalance();
      expect(flashBalance.toString()).to.equal((loan+fee.toNumber()).toString());
      let flashToken = await this.borrower.flashToken();
      expect(flashToken.toString()).to.equal(this.weth.address);
      let flashAmount = await this.borrower.flashAmount();
      expect(flashAmount.toString()).to.equal(loan.toString());
      let flashInitiator = await this.borrower.flashInitiator();
      expect(flashInitiator.toString()).to.equal(this.borrower.address);
  })

  it('needs to return funds after a flash loan', async function() {
    await expect(this.borrower.flashBorrowAndSteal(this.weth.address, 1)).to.be.revertedWith("ERC20: insufficient-approval");
  })

  it('should do two nested flash loans', async function() {
    await expect(this.borrower.flashBorrowAndReenter(this.weth.address, 1)).to.be.revertedWith("ReentrancyGuard: reentrant call")
  })
});
