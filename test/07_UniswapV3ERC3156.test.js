const ERC20Currency = artifacts.require('ERC20Mock')
const UniswapV3FactoryMock = artifacts.require('UniswapV3FactoryMock')
const UniswapV3PoolMock = artifacts.require('UniswapV3PoolMock')
const UniswapV3PoolPeriPhery = artifacts.require('UniswapV3PoolPeriPhery')
const UniswapV3ERC3156 = artifacts.require('UniswapV3ERC3156')
const FlashBorrower = artifacts.require('FlashBorrower')
const { BigNumber, utils } = require("ethers")

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
const { parseEther } = require("ethers/lib/utils")
const { MAX_UINT256 } = require("@openzeppelin/test-helpers/src/constants")
const bn = require('bignumber.js')

require('chai').use(require('chai-as-promised')).should()
bn.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 })


contract('07_UniswapV3ERC3156', (accounts) => {
  const [deployer, user1] = accounts
  let weth, dai, usdc, wethDaiPair, wethUsdcPair, uniswapFactory, lender, uniswapV3PoolPeriPhery
  let borrower
  // const reserves = new BN(100000000000);
  const reserves = parseEther('100000000000');
  
  const getMinTick = (tickSpacing) => Math.ceil(-887272 / tickSpacing) * tickSpacing
  const getMaxTick = (tickSpacing) => Math.floor(887272 / tickSpacing) * tickSpacing
  function expandTo18Decimals(n) {
    return BigNumber.from(n).mul(BigNumber.from(10).pow(18))
  }
  function encodePriceSqrt(reserve1, reserve0) {
    return BigNumber.from(
      new bn(reserve1.toString())
        .div(reserve0.toString())
        .sqrt()
        .multipliedBy(new bn(2).pow(96))
        .integerValue(3)
        .toString()
    )
  }
  beforeEach(async () => {
    weth = await ERC20Currency.new("WETH", "WETH")
    dai = await ERC20Currency.new("DAI", "DAI")
    usdc = await ERC20Currency.new("USDC", "USDC")

    uniswapFactory = await UniswapV3FactoryMock.new({ from: deployer })

    // First we do a .call to retrieve the pair address, which is deterministic because of create2. Then we create the pair.
    wethDaiPairAddress = await uniswapFactory.createPool.call(weth.address, dai.address, 3000)
    await uniswapFactory.createPool(weth.address, dai.address, 3000)
    wethDaiPair = await UniswapV3PoolMock.at(wethDaiPairAddress)

    wethUsdcPairAddress = await uniswapFactory.createPool.call(weth.address, usdc.address, 3000)
    await uniswapFactory.createPool(weth.address, usdc.address, 3000)
    wethUsdcPair = await UniswapV3PoolMock.at(wethUsdcPairAddress)
    
    await wethDaiPair.initialize(encodePriceSqrt(1, 1))
    await wethDaiPair.setFeeProtocol(6, 6)
    await wethDaiPair.increaseObservationCardinalityNext(4)

    await wethUsdcPair.initialize(encodePriceSqrt(1, 1))
    await wethUsdcPair.setFeeProtocol(6, 6)
    await wethUsdcPair.increaseObservationCardinalityNext(4)

    lender = await UniswapV3ERC3156.new(uniswapFactory.address, weth.address, dai.address)

    borrower = await FlashBorrower.new()
    uniswapV3PoolPeriPhery = await UniswapV3PoolPeriPhery.new()
    
    await weth.mint(deployer, reserves)
    await dai.mint(deployer, reserves)
    await usdc.mint(deployer, reserves)
    await weth.approve(uniswapV3PoolPeriPhery.address, MAX_UINT256)
    await dai.approve(uniswapV3PoolPeriPhery.address, MAX_UINT256)
    await usdc.approve(uniswapV3PoolPeriPhery.address, MAX_UINT256)

    await uniswapV3PoolPeriPhery.mint(
        wethDaiPair.address, 
        deployer, 
        getMinTick('60'),
        getMaxTick('60'), 
        expandTo18Decimals(100000), 
        {from: deployer}
      )

      await uniswapV3PoolPeriPhery.mint(
        wethUsdcPair.address, 
        deployer,
        getMinTick('60'),
        getMaxTick('60'), 
        expandTo18Decimals(100000), 
        {from: deployer}
      )
  })

  it('flash supply', async function () {
    let loan1 = await lender.maxFlashLoan(weth.address)
    let loan2 = await lender.maxFlashLoan(dai.address)
    let loan3 = await lender.maxFlashLoan(lender.address)

    const endLoan1 = parseInt(loan1 / 1e18)
    const endLoan2 = parseInt(loan2 / 1e18)
    const endLoan3 = parseInt(loan3 / 1e18)

    expect(endLoan1).eq(99999)
    expect(endLoan2).eq(99999)
    expect(endLoan3).eq(0)
  });

  it('flash fee', async function () {
    const one = BigNumber.from('1000000')
    const percentFee = BigNumber.from('3000')

    const wethFee = await lender.flashFee(weth.address, reserves)
    const wLoanWeth = (reserves.mul(one)).div(one.sub(percentFee))
    const wOwedWeth= (wLoanWeth.mul(one)).div(one.sub(percentFee))
    const endWethFee = wOwedWeth.sub(wLoanWeth)
    expect(wethFee.toString()).to.be.bignumber.equal(endWethFee.toString());

    const daiFee = await lender.flashFee(dai.address, reserves)
    const wLoanDai = (reserves.mul(one)).div(one.sub(percentFee))
    const wOwedDai = (wLoanDai.mul(one)).div(one.sub(percentFee))
    const endDaiFee = wOwedDai.sub(wLoanDai)
    expect(daiFee.toString()).to.be.bignumber.equal(endDaiFee.toString());

    await expectRevert(
      lender.flashFee(lender.address, reserves),
      "Unsupported currency"
    )
  });

  it('weth flash loan', async () => {
    const loan = await lender.maxFlashLoan(weth.address)
    const fee = await lender.flashFee(weth.address, loan)
    await weth.mint(borrower.address, fee, { from: user1 })

    await borrower.flashBorrowForUniswapV3(
      lender.address, 
      weth.address,
      loan,
      { from: user1 }
    )

    const balanceAfter = await weth.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(loan.add(fee).toString())
    const flashAmount = await borrower.flashAmount()
    flashAmount.toString().should.equal(loan.toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(fee.toString())
    const flashSender = await borrower.flashSender()
    flashSender.toString().should.equal(borrower.address)
  })

  it('dai flash loan', async () => {
    const loan = await lender.maxFlashLoan(dai.address)
    const fee = await lender.flashFee(dai.address, loan)
    await dai.mint(borrower.address, fee, { from: user1 })
    await borrower.flashBorrowForUniswapV3(
      lender.address, 
      dai.address,
      loan,
      { from: user1 }
    )

    const balanceAfter = await dai.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(loan.add(fee).toString())
    const flashAmount = await borrower.flashAmount()
    flashAmount.toString().should.equal(loan.toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(fee.toString())
    const flashSender = await borrower.flashSender()
    flashSender.toString().should.equal(borrower.address)
  })
})
