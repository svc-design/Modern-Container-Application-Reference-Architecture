const express = require("express");
const router = express.Router();
const ListController = require("../controllers/ListController");

router.get("/list", ListController.getList);

module.exports = router;
