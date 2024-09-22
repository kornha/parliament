/**
 * Fetches base platform icon (favicon or similar) from a given URL
 * @param {string} domain - The URL to fetch the base platform image from
 * @return {Promise<string>} - The platform image URL
 */
const getImageFromURL = async function(domain) {
  const _url = `https://www.google.com/s2/favicons?sz=256&domain_url=${domain}`;
  return _url;
};

module.exports = {
  getImageFromURL,
};
