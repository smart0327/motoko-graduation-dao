import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory } from "../../../declarations/dao";
import canisterIds from "../../../../.dfx/local/canister_ids.json";

export const createActor = async (canisterId, options) => {
  const agent = new HttpAgent({ ...options?.agentOptions });
  await agent.fetchRootKey();

  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
    ...options?.actorOptions,
  });
};

export const createActorWithIdentity = async (identity) => {
  const actor = await createActor(e2e_tests_daoCanister, {
    agentOptions: {
      host: "http://localhost:4943",
      identity,
      fetch,
    },
  });
  return actor;
};

export const e2e_tests_daoCanister = canisterIds.dao.local;
export const e2e_tests_dao = await createActor(e2e_tests_daoCanister, {
  agentOptions: {
    host: "http://localhost:4943",
    fetch,
  },
});
export const e2e_tests_tokenCanister = canisterIds.token.local;
export const e2e_tests_token = await createActor(e2e_tests_tokenCanister, {
  agentOptions: {
    host: "http://localhost:4943",
    fetch,
  },
});
