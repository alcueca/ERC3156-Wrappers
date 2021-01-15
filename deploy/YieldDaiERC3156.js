const addresses = {
  '1' : {
      'fyDaiLP21Mar31': '0xb39221E6790Ae8360B7E8C1c7221900fad9397f9',
      'YieldMathWrapper': '0xfcb06dce37a98081900fac325255d92dff94a107',
  },
  '42' : {
      'fyDaiLP21Mar31': '0x08cc239a994A10118CfdeEa9B849C9c674C093d3',
      'YieldMathWrapper': '0x032994fd2282fde1b7eb0893db6ca9a592ae99c7',
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

    const lender = await deploy('YieldDaiERC3156', {
      from: deployer,
      deterministicDeployment: true,
      args: require(`./YieldDaiERC3156-args-${chainId}`),
    })
    console.log(`Deployed YieldDaiERC3156 to ${lender.address}`);
  }
};

module.exports = func;
module.exports.tags = ["YieldDaiERC3156"];