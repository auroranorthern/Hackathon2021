if (typeof firebase === 'undefined') throw new Error('hosting/init-error: Firebase SDK not detected. You must include it before /__/firebase/init.js');
var firebaseConfig = {
  apiKey: "AIzaSyDz91iOlI7rCUd9CYlE1Z7hjPBNU_93cBs",
  authDomain: "unicorn-day.firebaseapp.com",
  projectId: "unicorn-day",
  storageBucket: "unicorn-day.appspot.com",
  messagingSenderId: "20790593389",
  appId: "1:20790593389:web:4680fcb15f66f2a53bfc64"
};
if (firebaseConfig) {
  firebase.initializeApp(firebaseConfig);

  var firebaseEmulators = undefined;
  if (firebaseEmulators) {
    console.log("Automatically connecting Firebase SDKs to running emulators:");
    Object.keys(firebaseEmulators).forEach(function(key) {
      console.log('\t' + key + ': http://' +  firebaseEmulators[key].host + ':' + firebaseEmulators[key].port );
    });

    if (firebaseEmulators.database && typeof firebase.database === 'function') {
      firebase.database().useEmulator(firebaseEmulators.database.host, firebaseEmulators.database.port);
    }

    if (firebaseEmulators.firestore && typeof firebase.firestore === 'function') {
      firebase.firestore().useEmulator(firebaseEmulators.firestore.host, firebaseEmulators.firestore.port);
    }

    if (firebaseEmulators.functions && typeof firebase.functions === 'function') {
      firebase.functions().useEmulator(firebaseEmulators.functions.host, firebaseEmulators.functions.port);
    }

    if (firebaseEmulators.auth && typeof firebase.auth === 'function') {
      firebase.auth().useEmulator('http://' + firebaseEmulators.auth.host + ':' + firebaseEmulators.auth.port);
    }
  } else {
    console.log("To automatically connect the Firebase SDKs to running emulators, replace '/__/firebase/init.js' with '/__/firebase/init.js?useEmulator=true' in your index.html");
  }
}
