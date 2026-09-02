import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {setGlobalOptions} from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
setGlobalOptions({region: "europe-west1", maxInstances: 10});

/**
 * Statuts considérés comme "importants" pour le client : ce sont les
 * seuls qui déclenchent une notification push, pour ne pas noyer
 * l'utilisateur sous des alertes (ex: le passage à "en traitement" côté
 * atelier n'a pas besoin de le déranger).
 */
const messagesParStatut: Record<string, { titre: string; corps: string }> = {
  collectePlanifiee: {
    titre: "Collecte confirmée",
    corps: "Un collecteur va bientôt passer récupérer votre linge.",
  },
  pret: {
    titre: "Votre linge est prêt",
    corps: "Votre linge a été lavé et repassé, la livraison arrive.",
  },
  enLivraison: {
    titre: "En livraison",
    corps: "Votre linge est en route vers vous.",
  },
  livree: {
    titre: "Linge livré",
    corps: "Votre linge a été livré. Merci de votre confiance !",
  },
  annulee: {
    titre: "Commande annulée",
    corps: "Votre demande de collecte a été annulée.",
  },
};

export const notifierChangementStatut = onDocumentUpdated(
  "commandes/{commandeId}",
  async (event) => {
    const avant = event.data?.before.data();
    const apres = event.data?.after.data();
    if (!avant || !apres) return;

    if (avant.statut === apres.statut) return;

    const message = messagesParStatut[apres.statut as string];
    if (!message) return;

    const clientId = apres.clientId as string | undefined;
    if (!clientId) return;

    const clientSnap = await admin.firestore().collection("users").doc(clientId).get();
    const token = clientSnap.data()?.tokenNotification as string | undefined;
    if (!token) return;

    try {
      await admin.messaging().send({
        token,
        notification: {
          title: message.titre,
          body: message.corps,
        },
        data: {
          commandeId: event.params.commandeId,
          statut: apres.statut as string,
        },
        android: {
          priority: "high",
          notification: {channelId: "statuts_commandes"},
        },
      });
    } catch (erreur) {
      console.error(`Échec envoi notification pour la commande ${event.params.commandeId}`, erreur);
    }
  }
);
