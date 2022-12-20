import {Signer} from "ethers";
import {Caller, RockPaperScissors} from "../typechain-types";

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("InterContract", function(){
    let caller: Caller;
    let rps: RockPaperScissors;
    let account: Signer;

    beforeEach(async () => {
        [account] = await ethers.getSigners();

        const rpsFactory = await ethers.getContractFactory("RockPaperScissors");
        rps = await rpsFactory.deploy();
        await rps.deployed();

        const callerFactory = await ethers.getContractFactory("Caller");
        caller = await callerFactory.deploy(rps.address);
        await caller.deployed();
    });

    describe("Caller tests", () => {
        it("should create game", async () => {

            const gamesTotalBefore = await rps.connect(account).gamesTotal();
            expect(gamesTotalBefore).to.equal(0);

            await caller.connect(account).createGameWithMyself(
                ethers.utils.parseEther("1")
            );

            const gamesTotalAfter = await rps.gamesTotal();
            expect(gamesTotalAfter).to.equal(1);
        });
    });
});
