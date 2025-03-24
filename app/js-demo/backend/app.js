const express = require("express");
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

const routes = require("./app/routes");
app.use("/api", routes);

app.listen(port, () => {
  console.log("Server is running on port " + port);
});
