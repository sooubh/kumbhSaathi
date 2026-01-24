import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

// Send notification when a notification document is created
export const sendNotification = functions.firestore
  .document("notifications/{notificationId}")
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  .onCreate(async (snap, _context) => {
    const notification = snap.data();
    if (!notification) {
      console.log("No data associated with the event");
      return;
    }

    console.log("Sending notification:", notification.title);

    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      topic: notification.topic || "all_users",
    };

    try {
      const response = await admin.messaging().send(message);
      console.log("Successfully sent notification:", response);

      // Update status to sent
      await snap.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return response;
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (error: any) {
      console.error("Error sending notification:", error);

      // Update status to failed
      await snap.ref.update({
        status: "failed",
        error: error.message,
      });

      throw error;
    }
  });

// Auto-update crowd levels every 5 minutes
// export const updateCrowdLevels = functions.pubsub
//   .schedule("every 5 minutes")
//   // eslint-disable-next-line @typescript-eslint/no-unused-vars
//   .onRun(async (_context) => {
//     console.log("Auto-updating crowd levels...");

//     const db = admin.firestore();
//     const ghatsSnapshot = await db.collection("ghats").get();
//     const locationsSnapshot = await db.collection("user_locations").get();

//     // eslint-disable-next-line @typescript-eslint/no-explicit-any
//     const updates: Promise<any>[] = [];

//     for (const ghatDoc of ghatsSnapshot.docs) {
//       const ghat = ghatDoc.data();
//       const ghatLat = ghat.latitude;
//       const ghatLng = ghat.longitude;

//       // Count users within 100m
//       let nearbyCount = 0;
//       locationsSnapshot.forEach((locDoc) => {
//         const loc = locDoc.data();
//         const distance = getDistance(
//           ghatLat,
//           ghatLng,
//           loc.latitude,
//           loc.longitude
//         );
//         if (distance < 0.1) {
//           // 100m = 0.1km
//           nearbyCount++;
//         }
//       });

//       // Determine crowd level
//       let crowdLevel = "low";
//       if (nearbyCount >= 50) crowdLevel = "high";
//       else if (nearbyCount >= 10) crowdLevel = "medium";

//       // Update if changed
//       if (ghat.crowdLevel !== crowdLevel) {
//         updates.push(
//           ghatDoc.ref.update({
//             crowdLevel: crowdLevel,
//             userCount: nearbyCount,
//             lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
//           })
//         );
//       }
//     }

//     await Promise.all(updates);
//     console.log(`Updated ${updates.length} ghats`);

//     return null;
//   });

// Helper function to calculate distance
// function getDistance(
//   lat1: number,
//   lon1: number,
//   lat2: number,
//   lon2: number
// ): number {
//   const R = 6371; // Earth's radius in km
//   const dLat = toRad(lat2 - lat1);
//   const dLon = toRad(lon2 - lon1);
//   const a =
//     Math.sin(dLat / 2) * Math.sin(dLat / 2) +
//     Math.cos(toRad(lat1)) *
//     Math.cos(toRad(lat2)) *
//     Math.sin(dLon / 2) *
//     Math.sin(dLon / 2);
//   const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
//   return R * c;
// }
//
// function toRad(deg: number): number {
//   return deg * (Math.PI / 180);
// }
