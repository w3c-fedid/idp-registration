# IdP Registration API

A proposal to extend FedCM to allow RPs to ask for "any" registered IdP, as opposed to (or, in addition to) enumerating them.

<img width="1089" alt="Screenshot 2024-09-10 at 11 23 26" src="https://github.com/user-attachments/assets/9cf6a1e0-cfbe-4773-8ee5-7b638e6899b9">

## Stage

This is a [Stage 1](https://github.com/w3c-fedid/Administration/blob/main/proposals-CG-WG.md) proposal.

## Champions

- @samuelgoto
- @aaronpk
- @anderspitman

## Participate
- https://github.com/w3c-fedid/idp-registration

# The Problem

One of the problems on the web is that users are currently constrained by a small set of social login providers to login to Websites. Websites, in turn, are constrained by finite space in login flows, so they typically have to pick 2-5 large social login providers (e.g. facebook, google, twitter, linkedin, github, etc) that can represent a large fraction of their users, but, by construction, not all of them.

One of the most popular alternative to federation in login flows is email verification (or phone number). In as much as email verification is orders of magnitudes more cumbersome, it excels at giving users choice in a much healthier ecosystem: users can join large services (e.g. gmail, gmx, outlook), use large services as hosts (e.g. custom domains) or even run their own operation (e.g. spinning up SMTP and POP servers), and websites accept any email address without having to register or allow-list servers (e.g. as long as the server speaks SMTP/POP they are welcomed in).

This isn't particularly a new problem, nor the first time a community tried to tackle it. In fact, [OpenID 1.0](https://x.com/samuelgoto/status/1745147272055390295), [IndieAuth](https://indieweb.org/IndieAuth) and [Solid](https://solid.github.io/webid-profile/) all allowed users to identity themselves as URIs.

 Different people will give different answers, but one common thread that's clear from prior art (e.g. Dick Hardt's account of ["[...] it became clear average users did not know what to do with the OpenID prompt [...]"](https://x.com/DickHardt/status/1735056737844220279) and Justin Richer's account for [Why We Fail](https://x.com/justin__richer/status/1778681191693947078)) is that users struggle to accept the UX that were constructed: typically, an input box to invite the user to enter their domain name.

# The Proposal

Let me start by saying that it is currently far from clear that this proposal is sufficient to make an effect in this ecosystem, but it does seem to introduce a new dimension to it: the browser.

In this proposal, the browser acts as an intermediator between relying parties and identity providers, allowing (a) the latter to register with the browser so that (b) the former can request for any previously registered identity provider.

The first stage isn't much different from (the largely unsuccessful) `navigator.registerProtocolHandler()`, allowing any website to prompt the user for a permission to use it as a login provider. 

The API is largely TBD, but here is where we starting from:

```javascript
IdentityProvider.register("https://idp.example/config.json")
``` 

<img width="1089" alt="Screenshot 2024-09-10 at 11 24 16" src="https://github.com/user-attachments/assets/0d8805dd-5206-4baf-94b9-5701219910e8">

The second stage is also not much different from the current construction in FedCM, except that the relying party is now able to ask for "any" IdP rather than enumerate them:

```javascript
navigator.credentials.get({
  identity: {
    providers: [{
      configURL: "any",
      clientId: "https://rp.example",
      nonce: "123",
      type: "indieauth",
    }]
  }
});
```

# Where are things at?

If you follow this thread you'll find a massive amount of engagement from all parts of the Web.

* Chrome and Firefox have bee largely supportive ([example](https://github.com/fedidcg/FedCM/issues/240#issuecomment-1335421460)). Chrome has [a prototype behind a flag](https://github.com/fedidcg/FedCM/issues/240#issuecomment-2004650817) that it is actively developing based on the feedback here
* The IndieWeb and Solid community have been actively participating and built prototypes of IdPs, RPs (https://webmention.io/) and profiles of protocols (e.g. [FedCM for IndieAuth](https://indieweb.org/FedCM_for_IndieAuth) and [OAuth Profile](https://github.com/fedidcg/FedCM/issues/599), largely thanks to @aaronpk ).
* A series of people have used @aaronpk 's work to spin up their own IdP (including myself, [Mark Foster](https://x.com/mfosterio/status/1793354610477785179), [Paul Kinlan](https://x.com/Paul_Kinlan/status/1793947618831114685) and many others) and services and frameworks (such as @anderspitman 's [Last Login](https://github.com/fedidcg/FedCM/issues/240#issuecomment-2156057182) and @sebadob 's [reathy](https://github.com/fedidcg/FedCM/issues/240#issuecomment-2136023482)).

# Open Questions

I think at this point, it is clear to me that there is something special here that is worth trying: this extension to FedCM seems to represent a diverse and rich set of communities. This API depends on w3c-fedid/FedCM#319, but it is something that we should be actively working on.

I think that what's yet to be seen is whether Relying Parties are going to find sufficient value in this construction. Based on the engagement in this thread, I think we arrived at something that browser vendors and users (as identity providers) are going to be excited about, but this is a three sided market, and Relying Parties are yet to join the party. 

There is much to believe that, due to FedCM's construction, this scheme is going to be a net-positive for Relying Parties, because calling the FedCM API without any registered Identity Provider has no negative effect (nothing is displayed, no real estate is taken), whereas it has a positive effect with a registered Identity Provider (something that the user has deliberately chosen). If that proves to be true, then it becomes an ergonomics and cost-benefit problem: are there going to be enough users that want to bring their own IdP that outweigh the cost paid by the RP to call the FedCM API?

All in all, this is an extension that is still early, and has as much potential as it has open questions, but seems so far worth taking a few leaps of faith.
