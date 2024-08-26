import { resolve } from "node:path";
import { Principal } from "@dfinity/principal";
import { Actor, PocketIc, createIdentity } from "@hadronous/pic";
import { describe, beforeEach, afterEach, inject, it, expect } from "vitest";
import { IDL } from "@dfinity/candid";
import {
  type _SERVICE as DAO_SERVICE,
  idlFactory as daoIdlFactory,
  Result,
  init,
} from "../../../declarations/dao/dao.did.js";
export const DAO_WASM_PATH = resolve(
  import.meta.dirname,
  "..",
  "..",
  "..",
  "..",
  ".dfx",
  "local",
  "canisters",
  "dao",
  "dao.wasm"
);
export const TOKEN_WASM_PATH = resolve(
  import.meta.dirname,
  "..",
  "..",
  "..",
  "..",
  ".dfx",
  "local",
  "canisters",
  "token",
  "token.wasm"
);

describe("member management", () => {
  let pic: PocketIc;
  let daoCanisterId: Principal;
  let tokenCanisterId: Principal;
  let daoActor: Actor<DAO_SERVICE>;

  beforeEach(async () => {
    pic = await PocketIc.create(inject("PIC_URL"), {
      application: 2,
    });
    const applicationSubnets = pic.getApplicationSubnets();
    const mainSubnet = applicationSubnets[0];
    const tokenSubnet = applicationSubnets[1];

    // daoCanisterId = await pic.createCanister({
    //   targetSubnetId: mainSubnet.id,
    // });
    // await pic.installCode({
    //   wasm: DAO_WASM_PATH,
    //   canisterId: daoCanisterId,
    //   targetSubnetId: mainSubnet.id,
    // });
    tokenCanisterId = await pic.createCanister({
      targetSubnetId: mainSubnet.id,
    });
    console.log("token canister id", tokenCanisterId.toText());
    await pic.installCode({
      wasm: TOKEN_WASM_PATH,
      canisterId: tokenCanisterId,
      targetSubnetId: mainSubnet.id,
    });

    const fixture = await pic.setupCanister<DAO_SERVICE>({
      idlFactory: daoIdlFactory,
      wasm: DAO_WASM_PATH,
      targetSubnetId: mainSubnet.id,
    });
    daoActor = fixture.actor;
    daoCanisterId = fixture.canisterId;
  });

  afterEach(async () => {
    await pic.tearDown();
  });

  it("success of registering member", async () => {
    let alice = createIdentity("AlicePassword");
    let bob = createIdentity("BobPassword");
    daoActor.setIdentity(alice);
    console.log("dao canister id", daoCanisterId.toText());
    console.log("token cainster id", tokenCanisterId.toText());
    const result: Result = await daoActor.registerMember({
      name: "Alice",
      role: { Student: null },
    });
  });
});
