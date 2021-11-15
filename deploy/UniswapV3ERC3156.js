const addresses = {
  '421611' : {
      'uniswapFactory': '0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e',
      'weth': '0x207eD1742cc0BeBD03E50e855d3a14E41f93A461',
      'dai': '0x8C0366c40801161A0375106fD3D9B29d4Fb9b918'
  }
}

  const func = async function ({ deployments, getNamedAccounts, getChainId }) {
    const { deploy, read, execute } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId()

    if (chainId === '31337') { // buidlerevm's chainId
      console.log('Local deployments not implemented')
      return
    } else {
      const lender = await deploy('UniswapV3ERC3156', {
        from: deployer,
        deterministicDeployment: true,
        args: [
          [addresses[chainId]['uniswapFactory']],
          [addresses[chainId]['weth']],
          [addresses[chainId]['dai']]
        ],
      })
      console.log(`Deployed UniswapV3ERC3156 to ${lender.address}`);
    }
  };
  
  module.exports = func;
  module.exports.tags = ["UniswapV3ERC3156"];
  