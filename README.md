# IdP Registration API

A proposal to extend [FedCM](https://w3c-fedid.github.io/FedCM/) to support open federations, in which a relying party accepts any identity provider that implements a given protocol.

**Spec:** https://w3c-fedid.github.io/idp-registration/

<img width="784" height="745" alt="IdP-3" src="https://github.com/user-attachments/assets/2aa4f45e-ea27-44df-a435-94ca092fce66" />

## Stage

This is a [Stage 1](https://github.com/w3c-fedid/Administration/blob/main/proposals-CG-WG.md) proposal.

## Champions

- @samuelgoto
- @aaronpk
- @anderspitman
- @ThisIsMissEm

## Participate

- https://github.com/w3c-fedid/idp-registration

# The problem

Web applications, or relying parties (RPs), use federated sign-in to authenticate users with an account they already have at an identity provider (IdP). FedCM lets the browser mediate this exchange: the RP lists the IdPs it accepts by their config URLs, and the browser shows the user's accounts at those IdPs.

This model assumes a **closed federation**: the RP knows in advance every IdP it accepts, and has a relationship with each of them.

In an **open federation**, any server that implements the federation's protocol can act as an IdP, and RPs accept all of them without a prior relationship. Examples:

- [IndieAuth](https://www.w3.org/TR/indieauth/): users are identified by a URL, e.g. `https://alice.example`.
- [AT Protocol](https://atproto.com/specs/handle): users are identified by a handle, e.g. `@alice.example`.
- [ActivityPub](https://www.w3.org/TR/activitypub/) servers: users are identified by an address, e.g. `alice@social.example`.
- [Solid](https://solid.github.io/webid-profile/): users are identified by a WebID.

Email works as an open federation in the same sense: an RP accepts an address at any mail domain.

Open-federation protocols typically ask the user to type an identifier (a URL, handle or address), so that the RP can discover the user's IdP from it. This requires users to know their identifier and to understand what the prompt is asking for.

OpenID 2.0 used this approach, which, according to one of its authors, [deployments declined by about half after their peak, as it became clear that average users did not know what to do with the OpenID prompt](https://x.com/DickHardt/status/1735056737844220279).

This proposal extends FedCM so that:

- an RP can request any IdP in an open federation, identified by a URL, without listing IdPs;
- the user can select an existing account without typing an identifier.


# The proposal

The browser keeps a list of the user's **handles**, such as `@alice.example`, `alice@social.example` or `https://alice.example`. An RP can then request any IdP that is the issuer of one of those handles and supports a federation the RP accepts.

**1. The IdP registers the user's handle** after the user signs in, with the user's permission:

```js
await navigator.login.setStatus("logged-in", {
  accounts: [{ id: "1234", name: "Alice", handle: "@alice.example" }]
});
await IdentityProvider.register("@alice.example");
```

The browser asks the user whether to save the handle:

<img width="784" height="745" alt="Registration prompt" src="https://github.com/user-attachments/assets/18dc0958-65f6-4222-bf77-c9d10eb1e9b8" />

**2. The RP requests a federation** (a protocol or profile, identified by a URL) instead of specific IdPs:

```js
const credential = await navigator.credentials.get({
  identity: {
    providers: [{ federation: "https://www.w3.org/TR/indieauth/", params: { nonce: "..." } }]
  }
});
```

The browser shows the accounts for the registered handles whose IdP lists that federation in its config file:

<img width="784" height="745" alt="Account chooser" src="https://github.com/user-attachments/assets/c4b9050d-95cd-439e-a7a5-013d0621d1a1" />

**3. The user can type a handle** that isn't registered yet. The browser resolves it to its IdP and adds it to the registered handles:

<img width="784" height="745" alt="Add another account" src="https://github.com/user-attachments/assets/99260e89-4e32-417d-96a7-45cb60b6dd8a" />

<img width="784" height="745" alt="IdP-2" src="https://github.com/user-attachments/assets/6ad59a1d-5b7b-497b-bc38-3100daa515b3" />

A handle's IdP is determined by the handle's domain, which can delegate to another site with a DNS record. The browser does not need protocol-specific logic. See [Handles](https://w3c-fedid.github.io/idp-registration/#handles) in the spec for how handles are parsed and resolved.

**Privacy.** A registered IdP receives no credentialed request before the user selects an account or chooses to sign in. This avoids the timing attack and the mismatch UI associated with FedCM's accounts endpoint. See [Privacy considerations](https://w3c-fedid.github.io/idp-registration/#privacy).

# Alternatives considered

- **Registering through `navigator.login.setStatus()`.** A registered handle has to outlive the user's session, while login status changes every time the user signs in or out. Registration can also show a prompt, which wouldn't work for the `Set-Login` header. See [The Handle Registry](https://w3c-fedid.github.io/idp-registration/#registry).
- **Registering a config URL instead of a handle.** With handles, registration by an IdP and entry by the user follow the same path, and a handle can move to another IdP without being registered again.
- **Passing the supported federations in `register()`.** Listing them in the config file means an IdP doesn't need to register again when the list changes.

# Where things are

- Chrome and Firefox have expressed support ([example](https://github.com/fedidcg/FedCM/issues/240#issuecomment-1335421460)), and Chrome has [a prototype behind a flag](https://github.com/fedidcg/FedCM/issues/240#issuecomment-2004650817).
- Members of the IndieWeb and Solid communities have built prototype IdPs, RPs and protocol profiles, for example [FedCM for IndieAuth](https://indieweb.org/FedCM_for_IndieAuth).

# Open questions

The main open question is whether RPs will adopt it. When the user has no registered IdPs in the requested federation, the call shows nothing, so the cost to an RP of trying it is low. The spec tracks other open questions as inline issues.
