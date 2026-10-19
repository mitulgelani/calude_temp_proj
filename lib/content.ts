export type Faq = { q: string; a: string };

export const HOME_FAQS: Faq[] = [
  {
    q: "What is Instagram comment-to-DM automation?",
    a: "It sends a private Instagram message to anyone who comments a keyword you choose. You post a Reel that says \"comment LINK\", and everyone who comments LINK gets your link in their DMs within seconds, without you opening the app.",
  },
  {
    q: "Is Hookline safe for my Instagram account?",
    a: "Hookline only uses Meta's official Instagram API with Instagram Login. You never share your password, nothing runs in a browser pretending to be you, and every message goes through the same private-reply endpoint Instagram built for this.",
  },
  {
    q: "Do I need a Business or Creator account?",
    a: "Yes. Instagram only allows messaging automation for professional accounts. Switching a personal account to Creator or Business is free in Instagram's settings and keeps your followers and posts.",
  },
  {
    q: "How fast do people get the DM?",
    a: "Usually within two to five seconds of commenting. Instagram notifies Hookline the moment a comment lands, Hookline checks your keyword and sends the message straight away.",
  },
  {
    q: "Can I make people follow me before they get the link?",
    a: "Yes, on the Creator plan. Hookline sends a short opener, and when the person replies it checks whether they follow you. Followers get the link right away; everyone else is asked to follow first.",
  },
  {
    q: "What if someone commented before I set up the automation?",
    a: "On the Creator plan you can re-run an automation on comments from the last seven days. Instagram allows a private reply up to seven days after a comment, so nobody who asked misses out.",
  },
  {
    q: "Does it work for Stories and DMs too?",
    a: "Yes. A DM automation replies when someone messages you a keyword, and Story replies arrive as DMs, so the same automation answers them.",
  },
  {
    q: "Is there a free plan?",
    a: "Yes. The Free plan includes 1,000 DMs a month, unlimited automations and link tracking, with no card required. Paid plans start at $9 or ₹399 a month.",
  },
];

export type ComparePage = {
  slug: string;
  competitor: string;
  title: string;
  description: string;
  intro: string;
  rows: { label: string; hookline: string; them: string }[];
  verdict: string;
};

export const COMPARE_PAGES: ComparePage[] = [
  {
    slug: "manychat",
    competitor: "ManyChat",
    title: "Hookline vs ManyChat: Instagram comment-to-DM compared",
    description:
      "ManyChat is a full chatbot builder. Hookline does one thing: send your link to everyone who comments a keyword. Compare pricing, setup time and features.",
    intro:
      "ManyChat is a capable visual chatbot builder that covers Instagram, Facebook Messenger, WhatsApp and SMS. Most creators use it for a single flow: comment a keyword, receive a link. Hookline is built only for that flow, which keeps setup to one screen and pricing flat.",
    rows: [
      { label: "Built on Meta's official API", hookline: "Yes", them: "Yes" },
      { label: "Setup", hookline: "One form, about two minutes", them: "Visual flow builder" },
      { label: "Pricing model", hookline: "Flat monthly price, unlimited DMs on paid plans", them: "Paid plans priced by number of contacts" },
      { label: "Free plan", hookline: "1,000 DMs a month", them: "Yes, with limits" },
      { label: "Follow-to-unlock links", hookline: "Creator plan", them: "Paid plans" },
      { label: "Re-run on past comments", hookline: "Creator plan, last 7 days", them: "Not a built-in feature" },
      { label: "WhatsApp, SMS, email", hookline: "No — Instagram only", them: "Yes" },
      { label: "Pricing in Indian rupees", hookline: "Yes, from ₹399", them: "USD" },
    ],
    verdict:
      "Choose ManyChat if you need multi-channel chatbots and complex branching flows. Choose Hookline if you want comment-to-DM working on your next Reel today at a flat price that doesn't grow with your audience.",
  },
  {
    slug: "linkdm",
    competitor: "LinkDM",
    title: "Hookline vs LinkDM: which Instagram auto-DM tool fits you?",
    description:
      "LinkDM and Hookline both send links to commenters through Instagram's official API. Compare plans, follow gates, re-runs and pricing in rupees.",
    intro:
      "LinkDM and Hookline solve the same problem with the same official Instagram API. The differences are in limits, pricing and a few creator-focused features.",
    rows: [
      { label: "Built on Meta's official API", hookline: "Yes", them: "Yes" },
      { label: "Free plan", hookline: "1,000 DMs a month", them: "1,000 DMs a month" },
      { label: "Entry paid plan", hookline: "$9 / ₹399 a month, unlimited DMs", them: "$19 a month (25,000 DMs, as of Oct 2026)" },
      { label: "Follow-to-unlock links", hookline: "Yes", them: "Yes" },
      { label: "Re-run on past comments", hookline: "Yes, last 7 days", them: "Check their current plans" },
      { label: "Link click tracking", hookline: "Every plan", them: "Check their current plans" },
      { label: "Accounts on top plan", hookline: "5 on Studio", them: "10 on Platinum+" },
    ],
    verdict:
      "If you run more than five accounts, LinkDM's top tier fits. For a single creator account, Hookline's Creator plan gives unlimited DMs for less than half the price.",
  },
];

export type Guide = {
  slug: string;
  title: string;
  description: string;
  readMinutes: number;
  sections: { heading: string; body: string[] }[];
  faqs: Faq[];
};

export const GUIDES: Guide[] = [
  {
    slug: "instagram-comment-to-dm",
    title: "How to set up Instagram comment-to-DM automation (2026 guide)",
    description:
      "A step-by-step guide to sending your link to everyone who comments a keyword on your Reels, with the Instagram rules you need to know.",
    readMinutes: 6,
    sections: [
      {
        heading: "What comment-to-DM actually does",
        body: [
          "Comment-to-DM turns a public comment into a private message. You end a Reel with \"comment GUIDE and I'll send it to you\", and everyone who comments GUIDE receives your link in their Instagram inbox a few seconds later.",
          "It works better than \"link in bio\" for two reasons. The viewer takes one action instead of four, and every comment tells Instagram the post is worth showing to more people.",
        ],
      },
      {
        heading: "Before you start",
        body: [
          "Your Instagram account must be a Creator or Business account. In Instagram, open Settings, then Account type and tools, and switch to a professional account. It's free and you keep your followers.",
          "Open Settings, then Messages and story replies, then Message controls, and make sure Allow access to messages under Connected tools is turned on. Without it, no tool can send DMs for you.",
        ],
      },
      {
        heading: "Set it up in Hookline",
        body: [
          "Create a free account and connect Instagram. You log in on Instagram's own page, so Hookline never sees your password.",
          "Create an automation: choose a specific post or any post, type your keywords (for example LINK, GUIDE, SEND), write the DM and paste your link. The preview shows exactly what people will receive.",
          "Add a public reply such as \"Sent! Check your DMs 📩\" so other viewers see that commenting works. Rotate two or three versions so your comment section doesn't look automated.",
        ],
      },
      {
        heading: "Write a caption that earns the comment",
        body: [
          "Say the keyword out loud in the video and put it in the first line of the caption. Use one short word in capitals; people copy what they see.",
          "Promise something specific: \"my 12-shot Reel template\", not \"more info\". The more concrete the reward, the more people comment.",
        ],
      },
      {
        heading: "Check it works",
        body: [
          "Ask a friend to comment your keyword from another account. The DM should arrive within a few seconds and the click appears in your Hookline dashboard when they open the link.",
          "If nothing arrives, check that message access is turned on in Instagram and that the automation is active and pointed at the right post.",
        ],
      },
    ],
    faqs: [
      {
        q: "Can I DM people who commented before I set it up?",
        a: "Yes, as long as the comment is less than seven days old. Hookline's re-run sends the DM to matching comments from the last seven days.",
      },
      {
        q: "Will Instagram ban me for auto-DMs?",
        a: "Tools built on Meta's official API, like Hookline, use the private-reply feature Instagram created for this purpose. Tools that ask for your password or automate a browser are the ones that put accounts at risk.",
      },
    ],
  },
  {
    slug: "instagram-private-replies-rules",
    title: "Instagram private replies: the rules Meta enforces",
    description:
      "The seven-day window, the one-message limit and the 24-hour window, explained in plain English for creators using auto-DM tools.",
    readMinutes: 4,
    sections: [
      {
        heading: "One message per comment",
        body: [
          "A private reply is a single DM sent in response to a comment. Instagram allows exactly one per comment. You can't send a second message unless the person writes back.",
          "That's why good automations put everything in the first message: the thank-you, the link and what to do next.",
        ],
      },
      {
        heading: "Seven days to reply",
        body: [
          "You can send a private reply up to seven days after the comment was posted. Comments on Instagram Live are the exception: those can only be answered while the broadcast is live.",
        ],
      },
      {
        heading: "The 24-hour window",
        body: [
          "When someone replies to your DM, you can message them freely for the next 24 hours. Hookline's follow-to-unlock feature relies on this: the opener asks them to reply, and their reply opens the window to send the link.",
        ],
      },
      {
        heading: "Professional accounts and message access",
        body: [
          "Only Creator and Business accounts can use messaging automation, and the account owner has to allow connected tools to access messages in Instagram's settings.",
        ],
      },
    ],
    faqs: [
      {
        q: "Can private replies include buttons?",
        a: "Meta documents private replies as text messages. Hookline sends your link as a tracked URL inside that text, which Instagram turns into a tappable link.",
      },
    ],
  },
  {
    slug: "comment-keyword-ideas",
    title: "40 comment keywords that get creators more DMs",
    description:
      "Tested keyword ideas for Instagram comment-to-DM campaigns, grouped by what you're giving away, with tips on choosing one.",
    readMinutes: 5,
    sections: [
      {
        heading: "How to pick a keyword",
        body: [
          "Use one word, easy to spell on a phone, that hints at the reward. Capitalise it in your caption. Avoid words people type anyway, like \"wow\", or your automation will fire on compliments.",
          "Add two or three spelling variants as extra keywords: LINK, LINKS and LNK all send the same DM in Hookline.",
        ],
      },
      {
        heading: "Free resources",
        body: ["GUIDE, PDF, TEMPLATE, CHECKLIST, EBOOK, NOTES, CHEATSHEET, WORKBOOK, PLANNER, SCRIPT"],
      },
      {
        heading: "Products and shopping",
        body: ["LINK, SHOP, PRICE, BUY, DEAL, CODE, SIZE, RESTOCK, DROP, WISHLIST"],
      },
      {
        heading: "Learning and courses",
        body: ["LEARN, CLASS, COURSE, WAITLIST, LESSON, ROADMAP, PROMPT, TOOLS, STACK, RESOURCES"],
      },
      {
        heading: "Travel, food and lifestyle",
        body: ["ITINERARY, MAP, RECIPE, PRESET, PLAYLIST, ROUTINE, PLAN, SPOTS, HOTEL, MENU"],
      },
    ],
    faqs: [
      {
        q: "Should the keyword be in capitals?",
        a: "In your caption, yes, because it stands out. Hookline ignores case when matching, so link, Link and LINK all trigger the DM.",
      },
    ],
  },
];

export function getGuide(slug: string) {
  return GUIDES.find((g) => g.slug === slug);
}

export function getCompare(slug: string) {
  return COMPARE_PAGES.find((c) => c.slug === slug);
}
