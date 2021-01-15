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