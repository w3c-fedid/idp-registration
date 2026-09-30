# IdP Registration API

A proposal to extend [FedCM](https://w3c-fedid.github.io/FedCM/) so that websites can ask for *any* identity provider the user has, instead of listing a few big ones.

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

Websites only have room for a handful of sign-in buttons, so they pick 2–5 large providers. Users whose identity lives elsewhere get left out: on a smaller provider, a custom domain, or a server they run themselves. Email verification doesn't have this problem, because any mail server works without being allow-listed.

Earlier attempts to fix this ([OpenID 1.0](https://x.com/samuelgoto/status/1745147272055390295), [IndieAuth](https://indieweb.org/IndieAuth), [Solid](https://solid.github.io/webid-profile/)) asked users to type their identity into a box, and [most users didn't know what to do with it](https://x.com/DickHardt/status/1735056737844220279).

# The proposal

The browser acts as an intermediary. It remembers the user's **handles**, such as `@alice.example`, `alice@social.example` or `https://alice.example`. Websites can then ask for any provider that issues one of those handles and speaks a protocol they accept.

**1. The identity provider registers the user's handle** after the user signs in, with the user's permission:

```js
await navigator.login.setStatus("logged-in", {
  accounts: [{ id: "1234", name: "Alice", handle: "@alice.example" }]
});
await IdentityProvider.register("@alice.example");
```

The browser asks the user whether to save the handle:

<img width="784" height="745" alt="Registration prompt" src="https://github.com/user-attachments/assets/18dc0958-65f6-4222-bf77-c9d10eb1e9b8" />

**2. The website asks for a federation** (a protocol or profile, identified by a URL) instead of a specific provider:

```js
const credential = await navigator.credentials.get({
  identity: {
    providers: [{ federation: "https://www.w3.org/TR/indieauth/", params: { nonce: "..." } }]
  }
});
```

The browser shows the accounts for every registered handle whose provider lists that federation in its config file:

<img width="784" height="745" alt="Account chooser" src="https://github.com/user-attachments/assets/c4b9050d-95cd-439e-a7a5-013d0621d1a1" />

**3. Users can also type a handle** that isn't registered yet. The browser finds the handle's provider and remembers the handle for next time:

<img width="784" height="745" alt="Add another account" src="https://github.com/user-attachments/assets/99260e89-4e32-417d-96a7-45cb60b6dd8a" />

<img width="784" height="745" alt="IdP-2" src="https://github.com/user-attachments/assets/6ad59a1d-5b7b-497b-bc38-3100daa515b3" />

A handle's provider is found from the handle's own domain, with an optional DNS record to delegate it to another site. No protocol-specific logic is needed in the browser. See [Handles](https://w3c-fedid.github.io/idp-registration/#handles) in the spec for how handles are parsed and resolved.

**Privacy.** Registered providers never receive a credentialed request before the user picks an account or chooses to sign in. That removes the timing attack and the mismatch UI that FedCM's accounts endpoint needs. See [Privacy considerations](https://w3c-fedid.github.io/idp-registration/#privacy).

# Alternatives considered

- **Registering through `navigator.login.setStatus()`.** A registered handle has to outlive the user's session, while login status changes every time the user signs in or out. Registration can also show a prompt, which wouldn't work for the `Set-Login` header. See [The Handle Registry](https://w3c-fedid.github.io/idp-registration/#registry).
- **Registering a config URL instead of a handle.** Registering a handle means a provider registering it and a user typing it follow the same path. It also lets a handle move to another provider without re-registering.
- **Passing the supported federations in `register()`.** Putting them in the config file means a provider doesn't need to register again when that list changes.

# Where things are

- Chrome and Firefox have been largely supportive ([example](https://github.com/fedidcg/FedCM/issues/240#issuecomment-1335421460)), and Chrome has [a prototype behind a flag](https://github.com/fedidcg/FedCM/issues/240#issuecomment-2004650817).
- The IndieWeb and Solid communities have built prototype identity providers, relying parties and protocol profiles, for example [FedCM for IndieAuth](https://indieweb.org/FedCM_for_IndieAuth).

# Open questions

The main open question is whether relying parties will adopt it. Calling the API costs them little: with no registered providers nothing is shown, and otherwise the user sees a provider they chose themselves. The spec tracks other open questions as inline issues.
