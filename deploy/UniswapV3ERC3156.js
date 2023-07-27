const func = async function ({ deployments, getNamedAccounts, getChainId }) {
    const { deploy, read, execute } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId()
    
    const uniswapFactory = '0x1F98431c8aD98523631AE4a59f267346ea31F984'
    const weth = '0x207eD1742cc0BeBD03E50e855d3a14E41f93A461'
    const dai = '0x8C0366c40801161A0375106fD3D9B29d4Fb9b918'

    if (chainId === '31337') { // buidlerevm's chainId
      console.log('Local deployments not implemented')
      return
    } else {
      const lender = await deploy('UniswapV3ERC3156', {
        from: deployer,
        deterministicDeployment: false,
        args: [
          uniswapFactory,
          weth,
          dai
        ],
      })
      console.log(`Deployed UniswapV3ERC3156 to ${lender.address}`);
    }
  };

  module.exports = func;
  module.exports.tags = ["UniswapV3ERC3156"];
  