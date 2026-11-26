
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

initializeApp({
  credential: applicationDefault(),
});

async function assignRole(uid, role) {
  const allowedRoles = ['Admin', 'OperationsStaff', 'Policyholder'];

  if (!allowedRoles.includes(role)) {
    throw new Error('Invalid role');
  }

  const auth = getAuth();

  const user = await auth.getUser(uid);

  await auth.setCustomUserClaims(uid, {
    ...user.customClaims,
    role: 'authenticated',
    app_role: role,
  });

  console.log(`Role ${role} assigned to ${uid}`);
}

const uid = 'WoCjBCYyCDXxMauyHImQWD9nMPt2';
const role = 'Policyholder';

assignRole(uid, role)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
