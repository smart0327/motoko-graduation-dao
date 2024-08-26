import { expect, test } from "vitest";
import { Actor, CanisterStatus, HttpAgent } from "@dfinity/agent";
import { Ed25519KeyIdentity } from "@dfinity/identity";
import { Principal } from "@dfinity/principal";
import { createActorWithIdentity, e2e_tests_token } from "./actor";
import { Result } from "../../../declarations/dao/dao.did";

test("success of registering member", async () => {
  let aliceIdentity = Ed25519KeyIdentity.generate(
    toUint8Array("AlicePassword")
  );
  let bobIdentity = Ed25519KeyIdentity.generate(toUint8Array("BobPassword"));
  let aliceActor = await createActorWithIdentity(aliceIdentity);
  let bobActor = await createActorWithIdentity(bobIdentity);

  let result: Result = (await aliceActor.registerMember({
    name: "Alice",
    role: { Student: null },
  })) as Result;
  expect(result).toEqual({ ok: null });
  result = (await bobActor.registerMember({
    name: "Bob",
    role: { Student: null },
  })) as Result;
  expect(result).toEqual({ ok: null });

  const aliceEntry = {
    name: "Alice",
    role: { Student: null },
  };
  const bobEntry = {
    name: "Bob",
    role: { Student: null },
  };
  result = (await aliceActor.getMember(aliceIdentity.getPrincipal())) as Result;
  expect(result).toEqual({ ok: aliceEntry });
  result = (await aliceActor.getMember(bobIdentity.getPrincipal())) as Result;
  expect(result).toEqual({ ok: bobEntry });

  let aliceBalance = await e2e_tests_token.balanceOf(
    aliceIdentity.getPrincipal()
  );
  expect(aliceBalance).toEqual(10);
  let bobBalance = await e2e_tests_token.balanceOf(bobIdentity.getPrincipal());
  expect(bobBalance).toEqual(10);
});

function toUint8Array(str: string): Uint8Array {
  const seed = new Uint8Array(32);
  seed.set(new TextEncoder().encode(str), 0);
  return seed;
  //   const array = new Uint8Array(32);
  //   for (let i = 0; i < 32; i++) {
  //       array[i] = i < str.length ? str.charCodeAt(i) : 0;
  //   }
  //   return array;
}
