/* eslint-disable max-len */
const {expect} = require("chai");
const sinon = require("sinon");
const rewire = require("rewire");
const storyFunctions = rewire("../ai/story_ai");
const claimFunctions = rewire("../ai/claim_ai");

describe("AI Tests", () => {
  describe("findStories", () => {
    it("should find 1 Story when there are none entered", async function() {
      this.timeout(20000);

      const candidateStories = [];

      const searchVectorsStub = sinon.stub().resolves(candidateStories);
      const writeTrainingDataStub = sinon.stub();

      storyFunctions.__set__("searchVectors", searchVectorsStub);
      storyFunctions.__set__("writeTrainingData", writeTrainingDataStub);
      claimFunctions.__set__("writeTrainingData", writeTrainingDataStub);

      const post = {
        pid: "fd6d6598-fb5a-5aba-9798-d3aa640047f4",
        eid: "93bed586-67df-4b5d-bfdf-3d7d730c37ae",
        xid: "1802087465341108529",
        url: "https://x.com/SenFettermanPA/status/1802087465341108529",
        poster: "pH1pUev5jNUpM8dPYaH4MJONWCkP",
        sourceType: "x",
        createdAt: 1719179502362,
        sourceCreatedAt: 1718486107000,
        video: null,
        title: "The loss of life in Gaza, military or civilian, is a tragedy that belongs to Hamas.\n\nI grieve as a father and my thoughts are with the families who lost their brave children.",
        photo: {
          photoURL: "https://pbs.twimg.com/media/GQJM_1ZWkAECNcx?format=jpg&name=small",
          description: "A news article screenshot from Politico with a headline stating '8 Israeli soldiers killed in southern Gaza in deadliest attack on troops in months.' The image shows a barren landscape with a security fence and a road running through it. There are some construction vehicles and equipment near the fence. The top of the screenshot features a red header with the Politico logo and navigation links to sections like Latest News, Magazine, California, Florida, and New Jersey.",
        },
        updatedAt: 1719179543731,
        status: "finding",
        vector: {
          _values: [0.0],
        },
      };


      const resp = await storyFunctions.findStories(post);
      const stories = resp.stories;

      const expectedDate = new Date("2024-06-15T16:15:07.000Z").getTime();
      const deltaTime = 6 * 3600 * 1000; // 6 hours in milliseconds
      const deltaLatLong = 0.5; // delta for latitude and longitude

      expect(searchVectorsStub.calledOnce).to.be.true;
      expect(writeTrainingDataStub.calledOnce).to.be.true;
      //
      expect(stories).to.be.an("array").that.is.not.empty;
      expect(stories[0]).to.have.property("sid", null);
      expect(stories[0]).to.have.property("title").that.is.not.null;
      expect(stories[0]).to.have.property("description").that.is.not.null;
      expect(stories[0]).to.have.property("headline").that.is.not.null;
      expect(stories[0]).to.have.property("subHeadline").that.is.not.null;
      expect(stories[0]).to.have.property("importance").that.is.within(0.4, 0.5);
      expect(new Date(stories[0].happenedAt).getTime()).to.be.closeTo(expectedDate, deltaTime);
      expect(stories[0].lat).to.be.closeTo(31.5, deltaLatLong);
      expect(stories[0].long).to.be.closeTo(34.47, deltaLatLong);
      expect(stories[0]).to.have.property("photos").that.is.an("array").that.is.not.empty;
      expect(stories[0].photos[0]).to.have.property("photoURL", "https://pbs.twimg.com/media/GQJM_1ZWkAECNcx?format=jpg&name=small");
      expect(stories[0].photos[0]).to.have.property("description").that.is.not.null;
    });

    it("should return the candidate Story", async function() {
      this.timeout(20000);

      const candidateStories = [
        {
          sid: "ad18d688-d656-4f4f-aac9-2ab6a9adf3ae",
          title: "Eight Israeli Soldiers Killed in Gaza Attack",
          headline: "Eight Israeli Soldiers Killed in Deadliest Attack in Months",
          subHeadline: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months.",
          description: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months. The attack occurred in southern Gaza and has been reported as the deadliest attack on troops in months.",
          importance: 0.45,
          photos: [
            {
              photoURL: "https://pbs.twimg.com/media/GQJM_1ZWkAECNcx?format=jpg&name=small",
            },
          ],
          happenedAt: 1718468100000,
          cids: [
            "c38657a4-b4ea-429f-9ac6-0e124ded7cb0",
            "f6feed16-3574-4473-8539-b27b684cb98c",
          ],
          createdAt: 1719327390006,
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.47,
            },
            geoHash: "sv8e0qkkc1",
          },
          updatedAt: 1719327390006,
          pids: [
            "fd6d6598-fb5a-5aba-9798-d3aa640047f4",
            "813416b8-b25f-5bbe-8aad-7f49496efd42",
          ],
          vector: {
            _values: [
              0.043307565,
            ],
          },
        },
        {
          sid: "c455fa6a-4ba4-47bd-a287-d023cee4b265",
          title: "Palestinian Peace Activists Against Hamas",
          headline: "Palestinian Peace Activists Speak Out Against Hamas",
          subHeadline: "Palestinian peace activists face imprisonment and death for criticizing Hamas.",
          description: "The Post discusses the plight of Palestinian peace activists who argue against Hamas' ideology and face imprisonment and death for their criticism.",
          updatedAt: 1719327389983,
          createdAt: 1719327389983,
          importance: 0.05,
          pids: [
            "813416b8-b25f-5bbe-8aad-7f49496efd42",
          ],
          photos: [
          ],
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.47,
            },
            geoHash: "sv8e0qkkc1",
          },
          happenedAt: 1718490718000,
          vector: {
            _values: [
              0.027923422,
            ],
          },
          cids: [
            "e1d63350-9626-4006-b512-8279e0a8fd62",
            "e769e0c5-affb-4486-a550-00a55f092542",
          ],
        },
      ];

      const searchVectorsStub = sinon.stub().resolves(candidateStories);
      const writeTrainingDataStub = sinon.stub();

      storyFunctions.__set__("searchVectors", searchVectorsStub);
      storyFunctions.__set__("writeTrainingData", writeTrainingDataStub);
      claimFunctions.__set__("writeTrainingData", writeTrainingDataStub);

      const post = {
        pid: "36aaf14b-1f38-5bff-95de-91d685d9f60e",
        eid: "3d6525bd-59bf-48d0-8e29-01e67c70a781",
        xid: "1802055345381998994",
        url: "https://x.com/Osint613/status/1802055345381998994",
        poster: "rDxLfZBvxL6IJlyvQrQGfykWO75m",
        sourceType: "x",
        createdAt: 1719327475056,
        sourceCreatedAt: 1718478449000,
        photo: null,
        video: null,
        title: "EIGHT ISRAELI SOLDIERS KILLED IN DEADLIEST GAZA INCIDENT SINCE JANUARY\n\nEight Israeli soldiers were killed in a blast in Rafah, southern Gaza, this morning, marking the deadliest IDF incident in the Strip since January. Only one soldier, Cpt. Wassem Mahmoud, 23, has been named. The other families have been notified, with names to be released later. The soldiers were in a Namer armored combat engineering vehicle (CEV) when it was hit by a major explosion. The convoy was heading to buildings captured after an overnight offensive against Hamas. The cause of the blast is under investigation. This brings the IDF death toll in the current offensive to 307.",
        vector: {
          _values: [0.045847878],
        },
        updatedAt: 1719327502023,
        status: "finding",
      };

      const resp = await storyFunctions.findStories(post);
      const stories = resp.stories;

      const expectedDate = new Date("2024-06-15T16:15:07.000Z").getTime();
      const deltaTime = 6 * 3600 * 1000; // 6 hours in milliseconds
      const deltaLatLong = 0.5; // delta for latitude and longitude

      expect(searchVectorsStub.calledOnce).to.be.true;
      expect(writeTrainingDataStub.calledOnce).to.be.true;
      //
      expect(stories).to.be.an("array").that.is.not.empty;
      expect(stories[0]).to.have.property("sid").that.is.equal(candidateStories[0].sid);
      expect(stories[0]).to.have.property("title").that.is.not.null;
      expect(stories[0]).to.have.property("description").that.is.not.equal(candidateStories[0].description);
      expect(stories[0]).to.have.property("headline").that.is.not.null;
      expect(stories[0]).to.have.property("subHeadline").that.is.not.equal(candidateStories[0].headline);
      expect(stories[0]).to.have.property("importance").that.is.within(0.4, 0.5);
      expect(new Date(stories[0].happenedAt).getTime()).to.be.closeTo(expectedDate, deltaTime);
      expect(stories[0].lat).to.be.closeTo(31.5, deltaLatLong);
      expect(stories[0].long).to.be.closeTo(34.47, deltaLatLong);
      expect(stories[0]).to.have.property("photos").that.is.an("array").that.is.not.empty;
      expect(stories[0].photos[0]).to.have.property("photoURL", "https://pbs.twimg.com/media/GQJM_1ZWkAECNcx?format=jpg&name=small");
      // photo description is not passed in so we don't output
      // expect(stories[0].photos[0]).to.have.property('description').that.is.not.null;
    });

    it("should return the candidate Story II", async function() {
      this.timeout(20000);

      const candidateStories = [
        {
          sid: "eba41008-d365-4628-a084-d2cfdb7f230d",
          title: "Dior Bag Production Costs",
          headline: "Dior Bags: $57 to Make, $2,780 to Buy",
          subHeadline: "Italian prosecutors reveal Dior's production costs for luxury bags.",
          description: "Italian prosecutors have uncovered that Dior pays only $57 to produce bags that retail for $2,780. This revelation raises questions about the pricing strategies of luxury brands and the value they offer to consumers.",
          updatedAt: 1720208264001,
          createdAt: 1720208264001,
          importance: 0.4,
          pids: [
            "8ecd0a3a-ba3d-5ec4-b57e-2ebd56660d81",
          ],
          photos: [
            {
              photoURL: "https://pbs.twimg.com/media/GRlQdu4XIAAbuSv?format=jpg&name=900x900",
            },
          ],
          location: {
            geoPoint: {
              _latitude: 41.9028,
              _longitude: 12.4964,
            },
            geoHash: "sr2ykk5te0",
          },
          happenedAt: 1720030520000,
          cids: [
            "b1cdb03f-af19-427a-83f1-938650e751e1",
          ],
          vector: {
            _values: [0.024750793],
          },
        },
      ];

      const searchVectorsStub = sinon.stub().resolves(candidateStories);
      const writeTrainingDataStub = sinon.stub();

      storyFunctions.__set__("searchVectors", searchVectorsStub);
      storyFunctions.__set__("writeTrainingData", writeTrainingDataStub);
      claimFunctions.__set__("writeTrainingData", writeTrainingDataStub);

      const post = {
        pid: "1e2ce086-cb7c-5bfb-b355-edb4d57b93f7",
        eid: "4836ec24-b3c5-49df-9390-9557f2c06a1e",
        xid: "1808695988678504850",
        url: "https://x.com/pitdesi/status/1808695988678504850",
        poster: "POrgYi2jvLyQ7r2Y8L3M1yR1qqcs",
        sourceType: "x",
        createdAt: 1720208296075,
        sourceCreatedAt: 1720061702000,
        video: null,
        title: "Italy raided factories & found that Armani and Dior bags are made by illegal Chinese workers in Italy who sleep in the workshop and make €2-3/hr. Both companies have been placed under Italian court administration. \n\nDior paid a supplier $57 to assemble* a handbag that sells for $2,780\n\nArmani bags that were sold to consumers for €1,800 cost €93* to make. \n\n(These don’t include raw materials costs)\n\nPeople often wrongly conflate higher prices for higher ethical standards.",
        photo: {
          photoURL: "https://pbs.twimg.com/media/GRnHZfLbMAEA-7_?format=jpg&name=900x900",
          description: "The image shows a large, industrial workshop where luxury handbags are manufactured. The workshop is spacious with high ceilings and large windows covered with red curtains. The floor is concrete, and the space is filled with various workstations and tables cluttered with materials, tools, and sewing machines. There are several cardboard boxes and storage units scattered around the area. The workshop appears to be in a state of disarray, with items and equipment not neatly organized. The image includes a watermark of the Carabinieri Tutela Lavoro, indicating that it was provided by Italy's Carabinieri police. The context of the image relates to a news article about raids finding luxury handbags being made by exploited workers in Italy, with a Milan court criticizing brands like Dior and Armani for failing to oversee their supply chains adequately.",
        },
        vector: {
          _values: [0.012712782],
        },
        updatedAt: 1720208328097,
        status: "finding",
      };

      const resp = await storyFunctions.findStories(post);
      const stories = resp.stories;

      expect(searchVectorsStub.calledOnce).to.be.true;
      expect(writeTrainingDataStub.calledOnce).to.be.true;
      //
      expect(stories).to.be.an("array").that.is.not.empty;
      expect(stories[0]).to.have.property("sid").that.is.equal(candidateStories[0].sid);
      expect(stories[0]).to.have.property("title").that.is.not.null;
      expect(stories[0]).to.have.property("description").that.is.not.equal(candidateStories[0].description);
      expect(stories[0]).to.have.property("headline").that.is.not.null;
      expect(stories[0]).to.have.property("subHeadline").that.is.not.equal(candidateStories[0].headline);
      expect(stories[0]).to.have.property("importance").that.is.within(0.4, 0.5);
    });

    it("should 1 or 2 Stories with 1 candidate", async function() {
      this.timeout(20000);

      const candidateStories = [{
        sid: "16681a80-caaa-40f7-a36b-95ba91cd2777",
        title: "Eight Israeli Soldiers Killed in Gaza Attack",
        headline: "Eight Israeli Soldiers Killed in Deadliest Attack in Months",
        subHeadline: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months.",
        description: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months. The loss of life, whether military or civilian, is a tragedy. The attack occurred in southern Gaza, and it is considered the deadliest attack on troops in months.",
        updatedAt: 1719239417826,
        createdAt: 1719239417826,
        importance: 0.45,
        pids: [
          "fd6d6598-fb5a-5aba-9798-d3aa640047f4",
        ],
        photos: [
          {
            photoURL: "https://pbs.twimg.com/media/GQJM_1ZWkAECNcx?format=jpg&name=small",
          },
        ],
        location: {
          geoPoint: {
            _latitude: 31.5,
            _longitude: 34.47,
          },
          geoHash: "sv8e0qkkc1",
        },
        happenedAt: 1718468107000,
        vector: {
          _values: [0.050173745],
        },
        cids: [
          "0cb194c1-6232-4c53-b21b-39740b767e8e",
          "66194ea0-7455-4895-bf6f-86301188801d",
        ],
      }];

      const searchVectorsStub = sinon.stub().resolves(candidateStories);
      const writeTrainingDataStub = sinon.stub();

      storyFunctions.__set__("searchVectors", searchVectorsStub);
      storyFunctions.__set__("writeTrainingData", writeTrainingDataStub);
      claimFunctions.__set__("writeTrainingData", writeTrainingDataStub);

      const post = {
        pid: "813416b8-b25f-5bbe-8aad-7f49496efd42",
        eid: "9e3384a9-78ca-4dc8-8dc4-f823041de0a1",
        xid: "1802106804039557412",
        url: "https://x.com/aziz0nomics/status/1802106804039557412",
        poster: "pH1pUev5jNUpM8dPYaH4MJONWCkP",
        sourceType: "x",
        createdAt: 1719239560492,
        sourceCreatedAt: 1718490718000,
        video: null,
        title: "To say that all Palestinians are guilty for the crimes of Hamas is a terrible insult to the Palestinian peace activists who argue against Hamas' ideology every day and many who Hamas imprisoned and killed just for criticising their ideas.",
        photo: null,
        updatedAt: 1719239589591,
        status: "finding",
        vector: {
          _values: [0.0],
        },
      };

      const resp = await storyFunctions.findStories(post);
      const stories = resp.stories;

      expect(searchVectorsStub.calledOnce).to.be.true;
      expect(writeTrainingDataStub.calledOnce).to.be.true;
      // allowing one or two stories to be returned since this is very close, ideally should be 1
      expect(stories).to.be.an("array");
      expect(stories.length).to.be.oneOf([1, 2]);
    });

    it("should find a different Story than the 2 similar candidate ones", async function() {
      this.timeout(20000);

      const candidateStories = [
        {
          sid: "920d0f63-906d-4f30-ba1e-547d6a9a06b4",
          title: "Eight Israeli Soldiers Killed in Gaza Attack",
          headline: "Eight Israeli Soldiers Killed in Deadliest Attack in Months",
          subHeadline: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months.",
          description: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months. The loss of life, whether military or civilian, is a tragedy. Thoughts are with the families who lost their brave children.",
          importance: 0.45,
          photos: [
            {
              photoURL: "https://pbs.twimg.com/media/GQJM_1ZWkAECNcx?format=jpg&name=small",
            },
          ],
          happenedAt: 1718468107000,
          cids: [
            "ecd01a02-5ad8-4166-89e8-590c0463d25d",
            "b455a92f-ff3e-4f48-a407-7dd2e5dcc8c4",
          ],
          createdAt: 1719244000384,
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.47,
            },
            geoHash: "sv8e0qkkc1",
          },
          updatedAt: 1719244000384,
          pids: [
            "fd6d6598-fb5a-5aba-9798-d3aa640047f4",
            "813416b8-b25f-5bbe-8aad-7f49496efd42",
          ],
          vector: {
            _values: [
              0.046831793,

            ],
          },
        },
        {
          sid: "4f4e6b9c-2c47-4d7d-908e-ee1ea9dc65b6",
          title: "Palestinian Peace Activists Against Hamas",
          headline: "Palestinian Peace Activists Speak Out Against Hamas",
          subHeadline: "Peace activists in Palestine face imprisonment and death for opposing Hamas.",
          description: "Palestinian peace activists argue against Hamas' ideology every day, and many have been imprisoned and killed by Hamas for criticizing their ideas.",
          updatedAt: 1719244000347,
          createdAt: 1719244000347,
          importance: 0.05,
          pids: [
            "813416b8-b25f-5bbe-8aad-7f49496efd42",
          ],
          photos: [
          ],
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.47,
            },
            geoHash: "sv8e0qkkc1",
          },
          happenedAt: 1718490718000,
          cids: [
            "1bf81883-143e-4a0e-9e53-4112195c57b4",
          ],
          vector: {
            _values: [
              0.040687602,
            ],
          },
        },
      ];

      const searchVectorsStub = sinon.stub().resolves(candidateStories);
      const writeTrainingDataStub = sinon.stub();

      storyFunctions.__set__("searchVectors", searchVectorsStub);
      storyFunctions.__set__("writeTrainingData", writeTrainingDataStub);
      claimFunctions.__set__("writeTrainingData", writeTrainingDataStub);

      const post = {
        pid: "b28b73b9-0567-51a5-8a7d-4dfe304e947c",
        eid: "9f38c7ea-4280-4a99-806b-edfb0c8ea5a1",
        xid: "1801949910909989069",
        url: "https://x.com/HowidyHamza/status/1801949910909989069",
        poster: "NlgbcHoHoP8FYosjni0NC9MIGn3Z",
        sourceType: "x",
        createdAt: 1719241333878,
        sourceCreatedAt: 1718453312000,
        photo: null,
        video: null,
        title: "I was talking to a friend from Gaza this morning, and I thought I knew what they were going through until he opened the camera and showed me the massive destruction of an area where we used to hang out. At first, I were unsure of him because I struggled to recall the neighborhood, which I used to visit at least once each week. Observing people's shapes can reveal how they are suffering as a result of the scarcity of food entering Gaza. Tents are erected over the rubble of ruined buildings, leaving people vulnerable, without privacy, and suffering from horrible conditions,the sound of air drones and combats is ongoing, all accompanied by a sense of isolation among Gazans, separation from the outside world due to Internet and energy blackouts, anarchy due to the lack of anybody to impose security, and a loss of optimism that all of this nightmare would end soon.",
        vector: {
          _values: [0.03093496],
        },
        updatedAt: 1719241354503,
        status: "finding",
      };

      const resp = await storyFunctions.findStories(post);
      const stories = resp.stories;

      const expectedDate = new Date("2024-06-15T16:15:07.000Z").getTime();
      const deltaTime = 6 * 3600 * 1000; // 6 hours in milliseconds
      const deltaLatLong = 0.5; // delta for latitude and longitude

      expect(searchVectorsStub.calledOnce).to.be.true;
      expect(writeTrainingDataStub.calledOnce).to.be.true;
      //
      expect(stories).to.be.an("array").that.has.lengthOf(1);
      expect(stories[0]).to.have.property("sid", null);
      expect(stories[0]).to.have.property("title").that.is.not.null;
      expect(stories[0]).to.have.property("description").that.is.not.null;
      expect(stories[0]).to.have.property("headline").that.is.not.null;
      expect(stories[0]).to.have.property("subHeadline").that.is.not.null;
      expect(stories[0]).to.have.property("importance").that.is.within(0.19, 0.41);
      expect(new Date(stories[0].happenedAt).getTime()).to.be.closeTo(expectedDate, deltaTime);
      expect(stories[0].lat).to.be.closeTo(31.5, deltaLatLong);
      expect(stories[0].long).to.be.closeTo(34.47, deltaLatLong);
      expect(stories[0].photos).to.be.an("array").that.has.lengthOf(0);
    });

    it("should find 1 Story not 0", async function() {
      this.timeout(20000);

      const candidateStories = [
        {
          sid: "920d0f63-906d-4f30-ba1e-547d6a9a06b4",
          title: "Eight Israeli Soldiers Killed in Gaza Attack",
          headline: "Eight Israeli Soldiers Killed in Deadliest Attack in Months",
          subHeadline: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months.",
          description: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months. The loss of life, whether military or civilian, is a tragedy. Thoughts are with the families who lost their brave children.",
          importance: 0.45,
          photos: [
            {
              photoURL: "https://pbs.twimg.com/media/GQJM_1ZWkAECNcx?format=jpg&name=small",
            },
          ],
          happenedAt: 1718468107000,
          cids: [
            "ecd01a02-5ad8-4166-89e8-590c0463d25d",
            "b455a92f-ff3e-4f48-a407-7dd2e5dcc8c4",
          ],
          createdAt: 1719244000384,
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.47,
            },
            geoHash: "sv8e0qkkc1",
          },
          updatedAt: 1719244000384,
          pids: [
            "fd6d6598-fb5a-5aba-9798-d3aa640047f4",
            "813416b8-b25f-5bbe-8aad-7f49496efd42",
          ],
          vector: {
            _values: [
              0.046831793,

            ],
          },
        },
        {
          sid: "4f4e6b9c-2c47-4d7d-908e-ee1ea9dc65b6",
          title: "Palestinian Peace Activists Against Hamas",
          headline: "Palestinian Peace Activists Speak Out Against Hamas",
          subHeadline: "Peace activists in Palestine face imprisonment and death for opposing Hamas.",
          description: "Palestinian peace activists argue against Hamas' ideology every day, and many have been imprisoned and killed by Hamas for criticizing their ideas.",
          updatedAt: 1719244000347,
          createdAt: 1719244000347,
          importance: 0.05,
          pids: [
            "813416b8-b25f-5bbe-8aad-7f49496efd42",
          ],
          photos: [
          ],
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.47,
            },
            geoHash: "sv8e0qkkc1",
          },
          happenedAt: 1718490718000,
          cids: [
            "1bf81883-143e-4a0e-9e53-4112195c57b4",
          ],
          vector: {
            _values: [
              0.040687602,
            ],
          },
        },
      ];

      const searchVectorsStub = sinon.stub().resolves(candidateStories);
      const writeTrainingDataStub = sinon.stub();

      storyFunctions.__set__("searchVectors", searchVectorsStub);
      storyFunctions.__set__("writeTrainingData", writeTrainingDataStub);
      claimFunctions.__set__("writeTrainingData", writeTrainingDataStub);

      const post = {
        pid: "7557196b-f9c8-5859-8f4f-f00ba59d35cc",
        eid: "c5ea57fe-1dfe-4455-a477-276d5977dc3a",
        xid: "1796415146077954329",
        url: "https://x.com/shaunmmaguire/status/1796415146077954329",
        poster: "WUjnDMyczVTMHAWmfPj9IPwQhn4s",
        sourceType: "x",
        createdAt: 1720117558712,
        sourceCreatedAt: 1717104783000,
        photo: null,
        video: null,
        title: "I would much prefer for my children to become Ivanka Trump than Hunter Biden",
        vector: {
          _values: [0.0141365705],
        },
        updatedAt: 1720117578055,
        status: "finding",
      };

      const resp = await storyFunctions.findStories(post);
      const stories = resp.stories;

      expect(searchVectorsStub.calledOnce).to.be.true;
      expect(writeTrainingDataStub.calledOnce).to.be.true;
      //
      expect(stories).to.be.an("array").that.has.lengthOf(1);
      expect(stories[0]).to.have.property("sid", null);
      expect(stories[0]).to.have.property("title").that.is.not.null;
      expect(stories[0]).to.have.property("description").that.is.not.null;
      expect(stories[0]).to.have.property("headline").that.is.not.null;
      expect(stories[0]).to.have.property("subHeadline").that.is.not.null;
      expect(stories[0]).to.have.property("importance").that.is.within(0.0, 0.11);
      expect(stories[0].photos).to.be.an("array").that.has.lengthOf(0);
    });

    it("should merge candidate Stories into 1 Story", async function() {
      this.timeout(20000);

      const candidateStories = [
        {
          sid: "be8c44bd-6f25-40c3-85c2-f023c1a73cfa",
          title: "IDF Hannibal Directive on October 7",
          headline: "IDF Used Hannibal Directive to Prevent Hamas Capturing Soldiers",
          subHeadline: "IDF's Hannibal directive on October 7 aimed to prevent Hamas from taking soldiers captive, potentially endangering civilians.",
          description: "Documents and testimonies obtained by Haaretz reveal that the IDF employed the Hannibal operational order on October 7 to prevent soldiers from being taken captive by Hamas. This directive, which directs the use of force to prevent soldiers from being taken into captivity, was employed at three army facilities infiltrated by Hamas, potentially endangering civilians as well.",
          updatedAt: 1720364209180,
          createdAt: 1720364209180,
          importance: 0.5,
          pids: [
            "2530edc8-d2c1-53c0-a03e-0e9ec2f5bba7",
          ],
          photos: [
            {
              photoURL: "https://pbs.twimg.com/media/GR31G_KXoAAY-m7?format=jpg&name=small",
            },
          ],
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.5,
            },
            geoHash: "sv8e1n6hu3",
          },
          happenedAt: 1728259200000,
          vector: {
            _values: [0.007416474],
          },
          cids: [
            "e3d23623-971e-4667-9795-5177de5d8338",
            "5ec58051-4b92-44d4-95a5-6c793b0fda05",
          ],
        },
        {
          sid: "9f033986-e120-48c5-b0a6-83773cec65ec",
          title: "Hannibal Directive Used on October 7",
          headline: "Israel Used Hannibal Directive on October 7",
          subHeadline: "Haaretz confirms Israel's use of the Hannibal directive on October 7, targeting vehicles and areas near Gaza.",
          description: "Haaretz confirms that Israel used the Hannibal directive on October 7, which included orders to attack any vehicle driving towards Gaza, indiscriminately bomb the area with mortar shells and artillery, and make it a 'kill zone'. Drones were also dispatched to attack the Re’im outpost close to the Nova festival. The directive was employed at three army facilities infiltrated by Hamas, potentially endangering civilians.",
          updatedAt: 1720364195307,
          createdAt: 1720364195307,
          importance: 0.6,
          pids: [
            "a9d63e0d-b7f1-5efd-ad49-e0b2a93c855a",
          ],
          photos: [
            {
              photoURL: "https://pbs.twimg.com/media/GR4OdeJX0AA4Myw?format=jpg&name=900x900",
            },
          ],
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.5,
            },
            geoHash: "sv8e1n6hu3",
          },
          happenedAt: 1728259200000,
          vector: {
            _values: [0.013121083],
          },
          cids: [
            "564cacd4-b41c-41fb-a659-aca31c4175af",
            "1a8007f7-7abd-472f-8f53-1d9957974882",
            "5f59f097-103c-42d3-abfa-d84890994c23",
            "a9f83c67-b002-4860-be46-2b55a08a7eb2",
          ],
        },
        {
          sid: "1fc6cc47-8074-455d-8362-b9b72ba5edc4",
          title: "Hannibal Directive on October 7",
          headline: "IDF Applied Hannibal Directive on October 7",
          subHeadline: "IDF forces ordered to create a death zone between Israel and Gaza on October 7.",
          description: "On October 7, the IDF applied the Hannibal Directive, ordering forces to make the area between Israel and Gaza a death zone for everyone and anything. This directive, which allows the military to eliminate its own soldiers and civilians if there is a suspicion they are being kidnapped, was extensively used on this day. The directive raises questions about the psychology of Israeli soldiers and the broader implications of such a policy.",
          updatedAt: 1720364222957,
          createdAt: 1720364222957,
          importance: 0.5,
          pids: [
            "df539597-c301-51fb-9d34-36598ad43546",
          ],
          photos: [
            {
              photoURL: "https://pbs.twimg.com/media/GR3kc_eXUAAJXTp?format=jpg&name=medium",
              description: null,
            },
          ],
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.5,
            },
            geoHash: "sv8e1n6hu3",
          },
          happenedAt: 1728259200000,
          cids: [
            "98635c84-7a0d-4897-b85d-9e056821223d",
          ],
          vector: {
            _values: [0.009893379],
          },
        },
        {
          sid: "972a8676-70b8-4586-ba4a-2ac6d28556dd",
          title: "IOF Officer Disappeared",
          headline: "IOF Officer Disappears After Bold Statement",
          subHeadline: "IOF officer who claimed Hamas fighters fear them has disappeared.",
          description: "An IOF officer, who once claimed that Hamas fighters do not dare to appear before them due to their strength, has reportedly disappeared. The incident highlights the ongoing conflict and tensions in the region.",
          updatedAt: 1720364233970,
          createdAt: 1720364233970,
          importance: 0.4,
          pids: [
            "dc6926a9-ecf9-5723-8fe2-ec98d5552440",
          ],
          photos: [
            {
              photoURL: "https://pbs.twimg.com/media/GR4NbIXWoAAAZxg?format=jpg&name=small",
            },
          ],
          location: {
            geoPoint: {
              _latitude: 31.5,
              _longitude: 34.4667,
            },
            geoHash: "sv8e0q3uu3",
          },
          happenedAt: 1720348559000,
          cids: [
            "da253d2e-38bf-4c3d-ad59-a21285f96025",
          ],
          vector: {
            _values: [0.0025450382],
          },
        },
      ];

      const searchVectorsStub = sinon.stub().resolves(candidateStories);
      const writeTrainingDataStub = sinon.stub();

      storyFunctions.__set__("searchVectors", searchVectorsStub);
      storyFunctions.__set__("writeTrainingData", writeTrainingDataStub);
      claimFunctions.__set__("writeTrainingData", writeTrainingDataStub);

      const post = {
        pid: "c635708d-7d7a-5de3-a910-edcd0bc793e7",
        eid: "0bc59027-0eeb-4db9-8088-c3728896d7c5",
        xid: "1809944602775822737",
        url: "https://x.com/Megatron_ron/status/1809944602775822737",
        poster: "ku6Ko7YvPSlpv1MdquK6vOqj0E4Z",
        sourceType: "x",
        createdAt: 1720372486262,
        sourceCreatedAt: 1720359395000,
        video: null,
        title: "BREAKING:\n\n Israeli Haaretz:\n\n\"IDF Ordered Hannibal Directive on October 7 to Prevent Hamas Taking Soldiers Captive\"\n\nDocuments and testimonies obtained by Haaretz reveal the Hannibal operational order, which directs the use of force to prevent soldiers being taken into captivity, was employed at three army facilities infiltrated by Hamas, potentially endangering civilians as well. \n\nHaaretz proves once again that Israel allowed October 7th to happen, and is responsible for the largest number of Israeli civilian casualties on that day.",
        photo: {
          photoURL: "https://pbs.twimg.com/media/GR43BkSWYAA71Km?format=jpg&name=small",
          description: "The image depicts a large crowd of people gathered at night, holding up Israeli flags and illuminated by numerous small lights, likely from mobile phones. The scene appears to be a public demonstration or rally, with participants showing solidarity or support for a cause. The Israeli flags are prominently displayed, featuring the blue Star of David and horizontal blue stripes on a white background. The background includes urban elements such as buildings and streetlights, indicating that the event is taking place in a city. The atmosphere is one of unity and collective action.",
        },
        vector: {
          _values: [0.027299045],
        },
        updatedAt: 1720372509650,
        status: "finding",
      };

      const resp = await storyFunctions.findStories(post);
      const stories = resp.stories;
      const removed = resp.removed;

      expect(searchVectorsStub.calledOnce).to.be.true;
      expect(writeTrainingDataStub.calledOnce).to.be.true;
      //
      expect(removed).to.be.an("array").that.has.lengthOf(3);
      expect(stories).to.be.an("array").that.has.lengthOf(1);
      expect(stories[0]).to.have.property("sid", null);
      expect(stories[0]).to.have.property("title").that.is.not.null;
      //
      expect(stories[0]).to.have.property("description").that.is.not.null;
      expect(stories[0]).to.have.property("headline").that.is.not.null;
      expect(stories[0]).to.have.property("subHeadline").that.is.not.null;
    });

    it("should merge candidate Stories into 1 Story II", async function() {
      this.timeout(20000);

      const candidateStories = [
        {
          sid: "209caf95-38c0-4681-9551-7de295005076",
          title: "Trump VP Selection Speculation",
          headline: "Trump's VP Pick: White Man or Marco Rubio?",
          subHeadline: "Speculation arises about Trump's potential VP pick being a white man or Marco Rubio.",
          importance: 0.2,
          photos: [
          ],
          happenedAt: 1720437495000,
          createdAt: 1720453981013,
          description: "Donald Trump is speculated to pick a white man or Marco Rubio, who is perceived by some as thinking he is white, for his Vice President. This speculation is based on a social media post by Dean Obeidallah. Additionally, there is speculation that Trump will not choose a running mate who is a hardliner on abortion. All the aspirants clearly understand that and are willing to abandon positions they held for decades with the exception of Tim Scott, which is one reason he won’t be picked. The new post suggests that the VP choice will not be someone from Florida, indicating a disappointment in the current political landscape.",
          updatedAt: 1720453981013,
          pids: [
            "5940df27-776d-584a-8190-fceaba2efb1c",
            "f4d494c2-cd24-5c3b-8e4e-9c0c08478bc5",
            "95417d89-4227-57d3-8d1d-f590dc13faae",
          ],
          vector: {
            _values: [-0.0247240931],
          },
          cids: [
            "e6ab464c-3127-4db8-a145-c10cf48c06be",
            "3f970a88-f08a-44d6-9531-20d30fc282d4",
            "be72f59e-c408-4343-8c58-dc3509635add",
            "b0b0d3be-9bf4-459f-a3c2-49a005a955ee",
            "6b06b405-b263-4bb8-9fbc-33bca66fa258",
          ],
        },
        {
          sid: "965ec75d-5fbe-400a-940b-b1ae55595e63",
          title: "Trump Vice President Appointment",
          headline: "Who Will Trump Appoint as Vice President?",
          subHeadline: "Public asked for opinions on Trump's Vice President appointment.",
          description: "A social media post is asking the public who they want to see President Trump appoint as his Vice President. The post does not provide any further details or context about the appointment.",
          importance: 0.1,
          happenedAt: 1720439040000,
          createdAt: 1720453358361,
          photos: [
            {
              photoURL: "https://pbs.twimg.com/media/GR-E1BdWQAAZIGG?format=jpg&name=900x900",
            },
          ],
          updatedAt: 1720453358361,
          pids: [
            "e5d28ded-9482-5547-adfb-985dc33778d3",
            "b0ac9d4a-444e-5fb7-8796-1d2023834a45",
          ],
          vector: {
            _values: [
              0.017925442,
            ],
          },
        },
        {
          sid: "5afa98c0-de3f-4c1d-b72b-a62366c6528f",
          title: "Trump VP Selection Announcement",
          headline: "Trump to Announce VP Selection This Week",
          subHeadline: "Donald Trump is expected to reveal his Vice Presidential pick this week.",
          importance: 0.4,
          photos: [
          ],
          happenedAt: 1720445104000,
          createdAt: 1720453825821,
          description: "Donald Trump is reportedly set to announce his Vice Presidential selection this week. The announcement is highly anticipated and has generated significant public interest. Additionally, there is speculation that Trump will not choose a running mate who is a hardliner on abortion. All the aspirants clearly understand that and are willing to abandon positions they held for decades with the exception of Tim Scott, which is one reason he won’t be picked. The new post suggests that Trump should wait a week to announce his VP, giving Biden another full week on defense over his age and infirmity. If Biden survives 8 days with Congress back in session, he’s further weakened. If he steps aside, the VP pick could be a counter move.",
          updatedAt: 1720453825821,
          pids: [
            "1a02c109-6648-5161-99df-9baa1c2f7f47",
            "f4d494c2-cd24-5c3b-8e4e-9c0c08478bc5",
            "c77d7bb0-de59-52b9-ac7e-ac89ee6cc8ad",
          ],
          vector: {
            _values: [-0.00487804138],
          },
          cids: [
            "6b06b405-b263-4bb8-9fbc-33bca66fa258",
            "b0b0d3be-9bf4-459f-a3c2-49a005a955ee",
            "e6ab464c-3127-4db8-a145-c10cf48c06be",
            "11a6f594-cdf7-48af-b13e-242cc4ebf0d6",
            "9991645f-5e3a-4b9f-8f5f-d7f00ee12f6a",
            "b41e89e1-46c4-4503-99fe-43ccd8f805e4",
            "3f970a88-f08a-44d6-9531-20d30fc282d4",
          ],
        },
      ];

      const searchVectorsStub = sinon.stub().resolves(candidateStories);
      const writeTrainingDataStub = sinon.stub();

      storyFunctions.__set__("searchVectors", searchVectorsStub);
      storyFunctions.__set__("writeTrainingData", writeTrainingDataStub);
      claimFunctions.__set__("writeTrainingData", writeTrainingDataStub);

      const post = {
        pid: "0b3ab782-cceb-536b-83f3-98e343e843f8",
        eid: "4fb6ab8c-43eb-4c3e-b7f0-e608d1c4948e",
        xid: "1810345796887298056",
        url: "https://x.com/AFpost/status/1810345796887298056",
        poster: "38ZFsoKUvh5yevTV9y9UdPdMyv6g",
        sourceType: "x",
        createdAt: 1720480619636,
        sourceCreatedAt: 1720455047000,
        video: null,
        title: "Senator JD Vance says he has “not gotten the call” from Trump asking him to be his VP.\n\nFollow: \n@AFpost",
        photo: {
          photoURL: "https://pbs.twimg.com/media/GR-j6DdWEAAwvM0?format=jpg&name=small",
          description: "The image features two men standing close together, both dressed in formal attire. The man on the left has light-colored hair, is wearing a dark suit with a white shirt, and a red tie. He appears to be gesturing with his left hand. The man on the right has dark hair and a beard, is wearing a dark suit with a white shirt, and a blue tie. He is standing in front of a microphone. The background is dark, and there are blurred elements that appear to be flags or banners.",
        },
        vector: {
          _values: [-0.027064322],
        },
        updatedAt: 1720480648256,
        status: "finding",
      };

      const resp = await storyFunctions.findStories(post);
      const stories = resp.stories;
      const removed = resp.removed;

      expect(searchVectorsStub.calledOnce).to.be.true;
      expect(writeTrainingDataStub.calledOnce).to.be.true;
      //
      expect(removed).to.be.an("array").that.has.lengthOf(3);
      expect(stories).to.be.an("array").that.has.lengthOf(1);
      expect(stories[0]).to.have.property("sid", null);
      expect(stories[0]).to.have.property("title").that.is.not.null;
      //
      expect(stories[0]).to.have.property("description").that.is.not.null;
      expect(stories[0]).to.have.property("headline").that.is.not.null;
      expect(stories[0]).to.have.property("subHeadline").that.is.not.null;
    });
  });

  afterEach(() => {
    sinon.restore();
  });
});
