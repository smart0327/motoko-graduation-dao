import { resolve } from "node:path";
import { Principal } from "@dfinity/principal";
import { Actor, PocketIc, createIdentity } from "@hadronous/pic";
import { describe, beforeEach, afterEach, inject, it } from "vitest";
import {
  type _SERVICE as DAO_SERVICE,
  idlFactory as daoIdlFactory,
  Result,
} from "../../src/declarations/dao/dao.did.js";
export const DAO_WASM_PATH = resolve(
  import.meta.dirname,
  "..",
  "..",
  ".dfx",
  "local",
  "canisters",
  "dao",
  "dao.wasm",
);
export const TOKEN_WASM_PATH = resolve(
  import.meta.dirname,
  "..",
  "..",
  ".dfx",
  "local",
  "canisters",
  "token",
  "token.wasm",
);

describe("member management", () => {
  let pic: PocketIc;
  let daoCanisterId: Principal;
  let tokenCanisterId: Principal;
  let daoActor: Actor<DAO_SERVICE>;

  beforeEach(async () => {
    pic = await PocketIc.create(inject("PIC_URL"));
    // const applicationSubnets = pic.getApplicationSubnets();
    // const mainSubnet = applicationSubnets[0];

    // // daoCanisterId = await pic.createCanister({
    // //   targetSubnetId: mainSubnet.id,
    // // });
    // // await pic.installCode({
    // //   wasm: DAO_WASM_PATH,
    // //   canisterId: daoCanisterId,
    // //   targetSubnetId: mainSubnet.id,
    // // });
    // tokenCanisterId = await pic.createCanister({
    //   targetSubnetId: mainSubnet.id,
    // });
    // await pic.installCode({
    //   wasm: TOKEN_WASM_PATH,
    //   canisterId: tokenCanisterId,
    //   targetSubnetId: mainSubnet.id,
    // });

    const fixture = await pic.setupCanister<DAO_SERVICE>({
      idlFactory: daoIdlFactory,
      wasm: DAO_WASM_PATH,
      // targetSubnetId: mainSubnet.id,
      // arg: IDL.encode(init({ IDL }), [tokenCanisterId]),
    });
    daoActor = fixture.actor;
  });

  afterEach(async () => {
    await pic.tearDown();
  });

  it("success of registering member", async () => {
    let alice = createIdentity("AlicePassword");
    let bob = createIdentity("BobPassword");
    daoActor.setIdentity(alice);
    const result: Result = await daoActor.registerMember({
      name: "Alice",
      role: { Student: null },
    });
  });
});
