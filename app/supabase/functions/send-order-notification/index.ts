// Supabase Edge Function: send-order-notification
// Deploy: supabase functions deploy send-order-notification
//
// Setup:
// 1. Create a Database Webhook in Supabase Dashboard:
//    Database → Webhooks → Create → "order_status_change"
//    Table: orders | Events: UPDATE | HTTP Request to this Edge Function URL
//
// 2. Set secrets:
//    supabase secrets set FCM_SERVER_KEY=your-firebase-cloud-messaging-server-key
//    OR use the Firebase service account JSON:
//    supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;

interface OrderRecord {
  id: string;
  user_id: string;
  status: string;
  total: number;
}

interface WebhookPayload {
  type: "UPDATE";
  table: string;
  record: OrderRecord;
  old_record: OrderRecord;
}

function getNotificationContent(status: string, orderId: string): { title: string; body: string } | null {
  const shortId = orderId.substring(0, 8).toUpperCase();

  switch (status) {
    case "CONFIRMED":
      return {
        title: "Order Confirmed! 🎉",
        body: `Your order #${shortId} has been confirmed and is being prepared`,
      };
    case "PREPARING":
      return {
        title: "Order Being Prepared 👨‍🍳",
        body: "Your groceries are being packed fresh for you",
      };
    case "OUT_FOR_DELIVERY":
      return {
        title: "Out for Delivery 🚴",
        body: "Your order is on the way! Track it live",
      };
    case "DELIVERED":
      return {
        title: "Order Delivered! ✅",
        body: "Your order has been delivered. Enjoy your groceries!",
      };
    case "CANCELLED":
      return {
        title: "Order Cancelled ❌",
        body: `Your order #${shortId} has been cancelled`,
      };
    default:
      return null;
  }
}

serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json();

    // Only process if status actually changed
    if (payload.old_record.status === payload.record.status) {
      return new Response(JSON.stringify({ message: "Status unchanged, skipping" }), { status: 200 });
    }

    const { id: orderId, user_id: userId, status } = payload.record;

    const notification = getNotificationContent(status, orderId);
    if (!notification) {
      return new Response(JSON.stringify({ message: "Unknown status, skipping" }), { status: 200 });
    }

    // Fetch user's FCM token from profiles
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("id", userId)
      .single();

    if (profileError || !profile?.fcm_token) {
      console.error("No FCM token found for user:", userId, profileError);
      return new Response(
        JSON.stringify({ message: "No FCM token found" }),
        { status: 200 }
      );
    }

    // Send FCM notification via HTTP v1 (legacy API)
    const fcmResponse = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: profile.fcm_token,
        notification: {
          title: notification.title,
          body: notification.body,
          sound: "default",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        data: {
          type: "order_status",
          order_id: orderId,
          status: status,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channel_id: "order_updates",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      }),
    });

    const fcmResult = await fcmResponse.json();
    console.log("FCM Response:", JSON.stringify(fcmResult));

    return new Response(
      JSON.stringify({ success: true, fcm: fcmResult }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Edge Function error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    );
  }
});
