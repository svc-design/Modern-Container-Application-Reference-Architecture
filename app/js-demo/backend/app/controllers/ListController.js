const List = require("../models/List");

exports.getList = (req, res) => {
  const userList = [
    { id: 1, name: "User 1" },
    { id: 2, name: "User 2" }
  ];

  res.json(userList);
};
