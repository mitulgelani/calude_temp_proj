import type { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";
import { SUPPORT_EMAIL } from "@/lib/site";

export const metadata: Metadata = {
  title: "Privacy policy",
  description: "How Hookline collects, uses and deletes data from your Instagram account and the people who message you.",
  alternates: { canonical: "/privacy" },
};

export default function PrivacyPage() {
  return (
    <LegalPage
      title="Privacy policy"
      sections={[
        {
          heading: "Who we are",
          body: [
            `Hookline provides Instagram comment-to-DM automation for creators and businesses. Contact us at ${SUPPORT_EMAIL} for any privacy question.`,
          ],
        },
        {
          heading: "What we collect",
          body: [
            "Your account: email address and name from sign-up, your plan and billing status.",
            "Your Instagram professional account, through Instagram's official API with your permission: account ID, username, profile picture, an access token (stored encrypted), and the posts you choose for automations.",
            "Interactions with your account: comments and messages that match your automations, the Instagram-scoped ID and username of the person who sent them, and whether a reply was delivered. We also count clicks on tracked links.",
          ],
        },
        {
          heading: "How we use it",
          body: [
            "Only to run the automations you set up: matching comments and messages to your keywords, sending the replies you wrote, and showing you activity and analytics. We do not sell data, use it for advertising, or message anyone on your behalf without an automation you created.",
          ],
        },
        {
          heading: "Instagram Platform data",
          body: [
            "We follow Meta's Platform Terms and Developer Policies. Instagram data is used only to provide Hookline's features to the account owner who connected it, and is deleted when that account is disconnected or the owner requests deletion.",
          ],
        },
        {
          heading: "Storage and security",
          body: [
            "Data is stored with our infrastructure providers (Supabase for the database, Vercel for hosting). Access tokens are encrypted with AES-256-GCM, every database table is protected by row-level security, and traffic is encrypted in transit.",
          ],
        },
        {
          heading: "Retention and deletion",
          body: [
            "Disconnecting an Instagram account deletes its token, automations, activity and contacts. Deleting your Hookline account removes everything. You can also request deletion at any time, see our data deletion page.",
          ],
        },
        {
          heading: "Your rights",
          body: [
            "You can access, correct, export or delete your data. Email us and we'll respond within 30 days.",
          ],
        },
      ]}
    />
  );
}
