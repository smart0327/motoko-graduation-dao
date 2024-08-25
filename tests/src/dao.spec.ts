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

import {
  type _SERVICE as TOKEN_SERVICE,
  idlFactory as tokenIdlFactory,
} from "../../src/declarations/token/token.did.js";
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

describe("Dao", () => {
  let pic: PocketIc;
  let tokenCanisterId: Principal;
  let daoActor: Actor<DAO_SERVICE>;

  beforeEach(async () => {
    pic = await PocketIc.create(inject("PIC_URL"));

    // Deploy the TOKEN canister
    const tokenFixture = await pic.setupCanister<TOKEN_SERVICE>({
      idlFactory: tokenIdlFactory,
      wasm: TOKEN_WASM_PATH,
    });
    tokenCanisterId = tokenFixture.canisterId;

    // Deploy the DAO canister
    const fixture = await pic.setupCanister<DAO_SERVICE>({
      idlFactory: daoIdlFactory,
      wasm: DAO_WASM_PATH,
      arg: IDL.encode(init({ IDL }), [tokenCanisterId]),
    });
    daoActor = fixture.actor;
  });

  afterEach(async () => {
    await pic.tearDown();
  });

  it("allows to register member", async () => {
    let alice = createIdentity("AlicePassword");
    daoActor.setIdentity(alice);

    const result: Result = await daoActor.registerMember({
      name: "Alice",
      role: { Student: null },
    });

    expect(result).toEqual(result);
  });
});
