const { expect } = require("chai");
const hardhat = require("hardhat");
const { ethers } = hardhat;


describe("MoonFomo V3", function() {
  let signers = [];
  let minter;
  let feeto;
  let valuableCoinsV3;
  let moonFomoV3;

  beforeEach(async function () {
    if (signers.length == 0) {
      signers = await ethers.getSigners();
      minter = signers[0]

      // We get the contract to deploy
      const ValuableCoinsV3 = await ethers.getContractFactory("ValuableCoinsV3");
      valuableCoinsV3 = await ValuableCoinsV3.deploy(minter.address, 60100);
      await valuableCoinsV3.deployed();

      const MoonFomoV3 = await ethers.getContractFactory("MoonFomoV3");
      moonFomoV3 = await MoonFomoV3.deploy(minter.address, valuableCoinsV3.address);
      await moonFomoV3.deployed();

      console.log("valuableCoinsV3: ", valuableCoinsV3.address);
      console.log("moonFomoV3: ", moonFomoV3.address);
    }
  });

  it("Round & Ticket Processing", async function() {    
    for (let i = 1; i < 8; i++)
      await valuableCoinsV3.transfer(signers[i].address, ethers.utils.parseEther("1000"));

    const _amount = ethers.utils.parseEther("1000");
    const _balance = await valuableCoinsV3.balanceOf(minter.address);    
    await valuableCoinsV3.approve(moonFomoV3.address, _balance);

    let _tx = await moonFomoV3.initRound(_amount);
    let _rc = await _tx.wait(); 
    let _event = _rc.events.find(event => event.event === 'RoundStarted');
    const [roundCount, roundTimer] = _event.args;
    console.log("InitRound done: ", roundCount.toString(), roundTimer.toString());

    _tx = await moonFomoV3.addTokensToRound(_amount);
    _rc = await _tx.wait(); 
    _event = _rc.events.find(event => event.event === 'RoundAddedTokens');
    const [roundCount1, newJackpot] = _event.args;
    console.log("RoundAddedTokens done: ", roundCount1.toString(), newJackpot.toString());

    for (let i = 1; i < 8; i++) {
      const _tickets = 1;
      const _balanceForTicket = await moonFomoV3.calcTicketCost(_tickets);
      await valuableCoinsV3.connect(signers[i]).approve(moonFomoV3.address, _balanceForTicket);

      _tx = await moonFomoV3.connect(signers[i]).buyTicket(_tickets);
      _rc = await _tx.wait(); 
      _event = _rc.events.find(event => event.event === 'TicketBought');
      const [buyer, ticketCount, ticketPrice] = _event.args;
      console.log(_tickets, "ticket bought: ", buyer.toString(), ticketCount.toString(), ticketPrice.toString());  
    }

    _tx = await moonFomoV3.endRound();
    _rc = await _tx.wait(); 
    _event = _rc.events.find(event => event.event === 'RoundEnded');
    const [roundCount2, jackpot, ticketCount] = _event.args;
    console.log("EndRound done: ", roundCount2.toString(), jackpot.toString(), ticketCount.toString());
  });
});
