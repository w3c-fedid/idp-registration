# IdP Registration API

A proposal to extend FedCM to allow RPs to ask for "any" registered IdP, as opposed to (or, in addition to) enumerating them.

<img width="1089" alt="Screenshot 2024-09-10 at 11 23 26" src="https://github.com/user-attachments/assets/9cf6a1e0-cfbe-4773-8ee5-7b638e6899b9">

## Stage

This is a [Stage 1](https://github.com/w3c-fedid/Administration/blob/main/proposals-CG-WG.md) proposal.

## Champions

- @samuelgoto
- @aaronpk
- @anderspitman
- @npm1

## Participate
- https://github.com/w3c-fedid/idp-registration

# The Problem

One of the problems on the web is that users are currently constrained by a small set of social login providers to login to Websites. Websites, in turn, are constrained by finite space in login flows, so they typically have to pick 2-5 large social login providers (e.g. facebook, google, twitter, linkedin, github, etc) that can represent a large fraction of their users, but, by construction, not all of them.

One of the most popular alternative to federation in login flows is email verification (or phone number). In as much as email verification is orders of magnitudes more cumbersome, it excels at giving users choice in a much healthier ecosystem: users can join large services (e.g. gmail, gmx, outlook), use large services as hosts (e.g. custom domains) or even run their own operation (e.g. spinning up SMTP and POP servers), and websites accept any email address without having to register or allow-list servers (e.g. as long as the server speaks SMTP/POP they are welcomed in).

This isn't particularly a new problem, nor the first time a community tried to tackle it. In fact, [OpenID 1.0](https://x.com/samuelgoto/status/1745147272055390295), [IndieAuth](https://indieweb.org/IndieAuth) and [Solid](https://solid.github.io/webid-profile/) all allowed users to identity themselves as URIs.

 Different people will give different answers, but one common thread that's clear from prior art (e.g. Dick Hardt's account of ["[...] it became clear average users did not know what to do with the OpenID prompt [...]"](https://x.com/DickHardt/status/1735056737844220279) and Justin Richer's account for [Why We Fail](https://x.com/justin__richer/status/1778681191693947078)) is that users struggle to accept the UX that were constructed: typically, an input box to invite the user to enter their domain name.

# The Proposal

It is currently far from clear that this proposal is sufficient to make an effect in this ecosystem, but it does seem to introduce a new dimension to it: the browser.

In this proposal, the browser acts as an intermediator between relying parties and identity providers, allowing (a) the latter to register with the browser so that (b) the former can request for any previously registered identity provider.

## Registration

The first stage isn't much different from `navigator.registerProtocolHandler()`, allowing any website to prompt the user for a permission to use it as a login provider. In this stage, an IdP must explicitly make itself available as a registered IdP by invoking the API:

```javascript
IdentityProvider.register("https://idp.example/config.json")
```

They may also choose to make themselves unavailable at a later point in time:
```javascript
IdentityProvider.unregister("https://idp.example/config.json")
```

When an IdP registers itself, it is attesting that it will use the [accounts push](https://github.com/fedidcg/LightweightFedCM?tab=readme-ov-file#fedcm-accounts-push) mechanism to store accounts in the user agent. These stored accounts may later be surfaced in an RP which requests a registered IdP. While the IdP may also have an accounts endpoint, only the stored accounts are surfaced when the IdP is being used as a registered IdP, e.g. when the RP does not explicitly request this IdP. 

```javascript
navigator.login.setStatus("logged-in", {
  accounts: [{
    id: "1234",
    name: "John Doe",
    email: "foobar@example.com",
    picture: "https://example.com/users/foobar.jpg",
  }],
});
```

This has some advantages:

* Improved privacy: no credentialed fetches are performed when a registered IdP is used. This means there is no silent timing attack problem, for instance. In particular, this means the user agent never has to show mismatch UI for registered IdPs! 
* Improved performance: the fetches required when using a registered IdP are greatly reduced (and could potentially be entirely removed) with this proposal, since the user agent knows the registered IdP and it also knows the accounts that it may show to the user when they visit the RP.

We initially thought it is required to promp the user during registration. That said, after some UX discussions, we believe it is acceptable to not prompt at this time for the following reasons:

* Registration happens when the user is visiting the IdP, which is not when the user gains any benefit from the registration. Asking the user to accept a registration for some potential future benefit seems off.
* It is hard to convey the meaning of registration to the user, especially in the IdP setting. Instead, the user agent can point the user to unregistration settings when surfacing registered accounts, in case the user finds them a nuisance.
* With the proposal we have, a registered IdP does not really gain anything privacy-wise solely from the registration (keep reading for details).

That being said, Chrome may add a prompt in the future. In general, this API should work with or without prompting when `register` is invoked. It is also encouraged for the user agent to check that the IdP has some pushed some accounts to the user agent at the time it attempts to register itself. This is a sanity check that the IdP has indeed implemented FedCM and that the user is logged in to the IdP.

## RP Invocation

The second stage consists of the RP performing a FedCM call. It's not much different from the current construction in FedCM, except that the relying party is now able to ask for "any" IdP rather than enumerate them, and it may specify a 'type' in order to only get registered IdPs that are compatible with the RP expectations (e.g. a type could be the protocol used):

```javascript
navigator.credentials.get({
  identity: {
    providers: [{
      configURL: 'any',
      type: "indieauth",
    }]
  }
});
```

A few things to note:
* configURL is not required (and in fact ignored) when `type` is passed. `clientId` is unlikely to be passed since it would vary by IdP. And `nonce` would be passed in `params`.
* IdP registration would only be supported in passive mode at the moment, since it presuposes multi IdP, which is not specified or implemented in active mode.
* The RP may also request non-registered IdPs in the same call. In case an IdP happens to be both registered and explicitly requested, the registration is 'ignored' to avoid duplication.

When registered IdP are requested:
1. The user agent looks up the list of IdPs which are registered AND have currently logged in accounts per the accounts push model.
2. For all of those IdPs, the user agent fetches the IdP's config file where it should contain at the very least a list of `types` that the IdP supports.
3. The user agent will show the stored accounts for IdPs which contain the `type` that was requested by the RP.
4. If the user selects an account from a registered IdP, the ID assertion endpoint is requested.

Notice that this in particular means that there is no requirement for there to be only one registered IdP per eTLD+1 since the well-known file is never queried for a registered IdP. In addition, in a FedCM login flow, an IdP that is purely registered only needs to worry about the manifest/config file and the ID assertion endpoint.

# Alternatives considered

For the IdP registration part, which is invoked from an IdP context, it is natural to consider bundling it into `navigator.login.setStatus`. This was not chosen for a few reasons:
* It would overload a method that is already somewhat: not only would it be now to set the login status AND store accounts, but ALSO to register an IdP. It is preferable for methods to have clear, distinct semantics, and the new `register` method does that.
* It would raise the question whether the header version would also have the capability to register. However, adding that would in turn be somewhat problematic because it is possible for a user agent to show UI as a result of that invocation, and having a header surface UI seems like a poor design choice.

For the `type`, it would be feasible to instead allow an array of `types` if an RP supports multiple kinds of registered IdPs. The `type` is just considered as a string for simplicity of the initial proposal.

Lastly, the `types` could be sent by the IdP in the registration call, but this has the drawback that the IdP would need to register itself again every time the list changes. By passing it via the config file, it does not need to register itself again when it changes the types it supports, which provides more flexibility to the IdP. Of course, the drawback is that this makes the construction of the account chooser from IdP registration to require one fetch instead of zero.

# Where are things at?

If you follow this thread you'll find a massive amount of engagement from all parts of the Web.

* Chrome and Firefox have bee largely supportive ([example](https://github.com/fedidcg/FedCM/issues/240#issuecomment-1335421460)). Chrome has [a prototype behind a flag](https://github.com/fedidcg/FedCM/issues/240#issuecomment-2004650817) that it is actively developing based on the feedback here
* The IndieWeb and Solid community have been actively participating and built prototypes of IdPs, RPs (https://webmention.io/) and profiles of protocols (e.g. [FedCM for IndieAuth](https://indieweb.org/FedCM_for_IndieAuth) and [OAuth Profile](https://github.com/fedidcg/FedCM/issues/599), largely thanks to @aaronpk ).
* A series of people have used @aaronpk 's work to spin up their own IdP (including myself, [Mark Foster](https://x.com/mfosterio/status/1793354610477785179), [Paul Kinlan](https://x.com/Paul_Kinlan/status/1793947618831114685) and many others) and services and frameworks (such as @anderspitman 's [Last Login](https://github.com/fedidcg/FedCM/issues/240#issuecomment-2156057182) and @sebadob 's [reathy](https://github.com/fedidcg/FedCM/issues/240#issuecomment-2136023482)).

# Open Questions

This extension to FedCM seems to represent a diverse and rich set of communities. This API depends on w3c-fedid/FedCM#319, but it is something that we should be actively working on.

What's yet to be seen is whether Relying Parties are going to find sufficient value in this construction. Based on the engagement in this thread, we think we arrived at something that browser vendors and users (as identity providers) are going to be excited about, but this is a three sided market, and Relying Parties are yet to join the party. 

There is much to believe that, due to FedCM's construction, this scheme is going to be a net-positive for Relying Parties, because calling the FedCM API without any registered Identity Provider has no negative effect (nothing is displayed, no real estate is taken), whereas it has a positive effect with a registered Identity Provider (something that the user has deliberately chosen). If that proves to be true, then it becomes an ergonomics and cost-benefit problem: are there going to be enough users that want to bring their own IdP that outweigh the cost paid by the RP to call the FedCM API?

All in all, this is an extension that is still early, and has as much potential as it has open questions, but seems so far worth taking a few leaps of faith.
