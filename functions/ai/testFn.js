const functions = require("firebase-functions/v2");
const {default: puppeteer} = require("puppeteer");
const {minify} = require("html-minifier-terser");
const cheerio = require("cheerio");
const {scrapeConfig} = require("../common/functions");
const {generateCompletions} = require("../common/llm");
/* eslint-disable max-len */

exports.testFn = functions.https.onCall(
    {
      ...scrapeConfig,
    },
    async (data, context) => {
      let end = false;
      let html = null;
      let screenshot = null;
      let url = null;
      let pageChanged = false;
      let resp = null;

      const browser = await puppeteer.launch({headless: false});
      const page = await browser.newPage();
      await page.setViewport({width: 926, height: 626});


      while (!end) {
        // If we have a URL from a previous step, load that page’s HTML
        if (url !== null) {
          console.log("going to page: ", url);
          await goToPage(page, url);
          url = null;
          pageChanged = true;
        }

        if (pageChanged) {
          console.log("loading html");
          html = await loadPageHtml(page);
          screenshot = await loadPageScreenshot(page);
          pageChanged = false;
        }

        console.log("Generating next step", url, html != null);
        resp = await executeNextStep(url, html, screenshot);
        console.log(resp);
        html = null;
        screenshot = null;


        // Now handle whatever instruction we got back.
        if (!resp) {
          // If there’s no response or something unexpected, break or handle as you see fit
          console.log("No valid instruction received. Ending session.");
          end = true;
          break;
        }

        // If the instruction says to end, break out of the loop
        if (resp.end) {
          console.log("Received an 'end' instruction. Stopping.");
          end = true;
          break;
        }

        // If the instruction says “navigate to this url,” store it in our url variable
        if (resp.url) {
          console.log("Navigating to:", resp.url);
          url = resp.url;
          continue;
        }

        // If it says “click,” we’d presumably open the page and click on the selector
        if (resp.click) {
          console.log("Clicking selector:", resp.click);
          let clicked = false;

          // 1) Try main page first
          try {
            // Wait until element is in the DOM and visible
            await page.waitForSelector(resp.click, {visible: true, timeout: 3000});

            // Scroll it into view
            await page.evaluate((sel) => {
              // eslint-disable-next-line no-undef
              const el = document.querySelector(sel);
              if (el) el.scrollIntoView();
            }, resp.click);

            // Small delay in case there's an animation
            await page.waitForTimeout(300);

            // Now click
            await page.click(resp.click);
            pageChanged = true;
            clicked = true;
          } catch (err) {
            console.error("Error clicking element in main page:", err);
          }

          // 2) If not found on main page, try all iframes
          if (!clicked) {
            console.log("Trying iframes for selector:", resp.click);
            const frames = page.frames();

            for (const frame of frames) {
              try {
                await frame.waitForSelector(resp.click, {visible: true, timeout: 2000});
                // Scroll into view in that frame
                await frame.evaluate((sel) => {
                  // eslint-disable-next-line no-undef
                  const el = document.querySelector(sel);
                  if (el) el.scrollIntoView();
                }, resp.click);

                await frame.waitForTimeout(300);

                // Then click inside the frame
                const handle = await frame.$(resp.click);
                await handle.click();

                pageChanged = true;
                clicked = true;
                console.log("Clicked in iframe with URL:", frame.url());
                break; // Stop checking other frames
              } catch (frameErr) {
                console.warn("Selector not found in frame with URL:", frame.url());
              }
            }
          }

          // 3) (Optional) If still not clicked, check for Shadow DOM
          //    You need to know the host or a strategy to find shadow roots.
          if (!clicked) {
            console.log("Could not find element in main page or iframes. Possibly shadow DOM or purely CSS-based?");

            // Example (very site-specific). You need to adapt this:
            // try {
            //   await page.evaluate(() => {
            //     const host = document.querySelector('my-web-component');
            //     if (host && host.shadowRoot) {
            //       const el = host.shadowRoot.querySelector('.popover-selector');
            //       if (el) el.click();
            //     }
            //   });
            //   clicked = true;
            //   pageChanged = true;
            // } catch (shadowErr) {
            //   console.warn("Shadow DOM approach failed:", shadowErr);
            // }

            // If we still haven't clicked, we might end or handle differently:
            if (!clicked) {
              console.error("Failed to find/click the popover or element. Ending session or handle differently.");
              end = true;
            }
          }

          continue;
        }

        // If it says “input,” we’d presumably type into an input box
        if (resp.input) {
          console.log("Typing into selector:", resp.input, " value:", resp.value);
          try {
          // Wait until the element is visible
            await page.waitForSelector(resp.input, {visible: true});

            // Optionally scroll it into view
            await page.evaluate((sel) => {
              // eslint-disable-next-line no-undef
              const el = document.querySelector(sel);
              if (el) el.scrollIntoView();
            }, resp.input);

            // Type the specified value
            await page.type(resp.input, resp.value, {delay: 100});
            pageChanged = true;
          } catch (err) {
            console.error("Error typing into element:", err);
            end = true;
          }
          continue;
        }

        // If it says “scroll,” handle scrolling
        if (resp.scroll) {
          console.log("Scrolling selector:", resp.scroll, " delta:", resp.delta);
          try {
            await page.waitForSelector(resp.scroll, {visible: true});
            // Example approach:
            await page.evaluate((scrollSelector, delta) => {
              // eslint-disable-next-line no-undef
              const elem = document.querySelector(scrollSelector);
              if (elem) {
                elem.scrollBy(0, delta);
              }
            }, resp.scroll, resp.delta);
          } catch (err) {
            console.error("Error scrolling:", err);
            end = true;
          }
          continue;
        }

        // If it says “human” (e.g. a captcha or something we can’t automate),
        // you could either end or do something else:
        if (resp.human) {
          console.log("Human help needed:", resp.human);
          // sleep 15s
          await new Promise((resolve) => setTimeout(resolve, 15000));
          pageChanged = true;
        }
      }

      await browser.close();

      return Promise.resolve();
    });


/* eslint-disable require-jsdoc */
async function goToPage(page, url) {
  await page.goto(url, {waitUntil: "networkidle2"});
}

async function loadPageScreenshot(page) {
  return await page.screenshot({fullPage: true});
}
async function loadPageHtml(page) {
  // Get full HTML
  let html = await page.content();

  // 1) Parse with cheerio
  const $ = cheerio.load(html);

  // 2) Remove script, style, head, iframe, noscript tags, etc.
  $("script, style, head, iframe, noscript, svg").remove();

  // 3) Remove any HTML comments
  $("*")
      .contents()
      .each((i, el) => {
        if (el.type === "comment") {
          $(el).remove();
        }
      });

  // 4) Get updated HTML from cheerio
  html = $.html();

  // 5) Minify the remaining HTML
  html = await minify(html, {
    collapseWhitespace: true,
    removeComments: true,
    removeOptionalTags: true,
    // removeEmptyAttributes: true,
  });

  return html;
}

async function executeNextStep(url, html, screenshot) {
  const messages = [
    {type: "text", text: `
      Please buy me an airline ticket. I'm going to Seattle Feb 12 and coming back Feb 14. Cheapest price please, at night.

      I will give you the html of the current html of the webpage I am on 
      (or null if we are just getting started). You will respond with the next step.

      You will be controlling a browser to help me buy the ticket. This will run in a loop,
      and you will be able to see the current html and generate a command for the next step.
      Prefer expedia for flights but you can try elsewhere.
      You can reply with the following outputs:

      {"url": "url to go to if you want the browswer to navigate to a url"}
      {"click_screenshot": {"x": <xcordinate for pupetteer to click>, "y":<xcordinate for puppeteer to click>}} // note viewport is 926x626
      {"click": "exactly valid string to call page.click in puppeteer. use only if click_screenshot doesn't make sense}"}
      {"input": "selector for an input box to type into, value: value to put in the box"}
      {"scroll": "selector to scroll within, delta: how far to scroll by in pixels"}
      {"human": "cannot get past this step, please help me, eg if there is a captcha or login"}
      {"end": "end the session"}
    `},
    {type: "text", text: "Current URL (if any) " + url},
    {type: "text", text: "Current HTML (if any): " + html},
    {type: "text", text: "Please respond with the next step in valid JSON that JSON.parse can understand"},
  ];

  if (screenshot) {
    messages.push({type: "text", text: "Current screenshot (base64):"});
    messages.push({type: "image", image: screenshot});
  }

  const result = await generateCompletions({
    messages,
    temperature: 0.0,
  });

  return result;
}
