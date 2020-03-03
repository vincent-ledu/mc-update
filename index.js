const axios = require("axios");

async function getLatestVersion(type) {
  return axios
    .get("https://launchermeta.mojang.com/mc/game/version_manifest.json")
    .then(function(response) {
      // handle success
      let mc_versions_urls = response.data.versions;
      let i = 0;
      for (; i < mc_versions_urls.length; i++) {
        if (mc_versions_urls[i].type == type) break;
      }
      return mc_versions_urls[i].url
    })
    .catch(function(error) {
      console.log(error);
      return "";
    });
}

async function getDownloadUrl(type) {
  const url = await getLatestVersion(type)
  return axios
    .get(url)
    .then(function(response) {
      // handle success
      console.log(
        response.data.downloads.server.url
      );
      return response.data.downloads.server.url
    })
    .catch(function(error) {
      console.log(error);
      return "";
    });
}

if (process.argv.length <= 2) {
  console.log("Please, indicate type of minecraft release, such as release, snapshot, ...")
  process.exit(1)
}

getDownloadUrl(process.argv[2]);
