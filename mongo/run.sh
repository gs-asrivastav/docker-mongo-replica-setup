#!/bin/bash
chmod +x /scripts/wait
/scripts/wait
mongo mongodb://mongo-rs0:27017 <<EOF
rs.initiate({
  "_id": "rs0",
  "members": [
    {
      "_id": 0,
      "host": "mongo-rs0:27017"
    },
    {
      "_id": 1,
      "host": "mongo-rs1:27017"
    }
  ]
})
rs.conf()
rs.slaveOk();
db.getMongo().setReadPref('nearest');
db.getMongo().setSlaveOk();
EOF

echo 'Sleeping for 10s for replica setup to complete.'
sleep 10;

mongo mongodb://$MONGO_HOSTNAMES/?replicaSet=$REPLICA_SET -- <<EOF
let databases = '$INITIALIZATION_DATABASES'.split(',')
databases.forEach(database => {
  let dev = db.getSiblingDB(database)
  dev.createUser({
    user: '$USER_NAME',
    pwd: '$USER_PWD',
    roles: [
      {
        role: 'root',
        db: 'admin',
      },
    ],
  });
})
EOF
echo "-- Intialization Complete --"
