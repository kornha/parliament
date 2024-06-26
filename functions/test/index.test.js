/* eslint-disable max-len */
const {expect} = require("chai");
const sinon = require("sinon");
const rewire = require("rewire");
const myFunctions = rewire("../ai/post_ai");

describe("AI Tests", () => {
  describe("findStories", () => {
    it("should find 1 Story when there are none entered", async function() {
      this.timeout(20000);

      const candidateStories = [];

      const searchVectorsStub = sinon.stub().resolves(candidateStories);
      const writeTrainingDataStub = sinon.stub();

      myFunctions.__set__("searchVectors", searchVectorsStub);
      myFunctions.__set__("writeTrainingData", writeTrainingDataStub);

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


      const stories = await myFunctions.findStories(post);

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

    it("should merge Stories to the candidate one", async function() {
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

      myFunctions.__set__("searchVectors", searchVectorsStub);
      myFunctions.__set__("writeTrainingData", writeTrainingDataStub);

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

      const stories = await myFunctions.findStories(post);

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

    it("should find a different Story than the similar candidate one", async function() {
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

      myFunctions.__set__("searchVectors", searchVectorsStub);
      myFunctions.__set__("writeTrainingData", writeTrainingDataStub);

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

      const stories = await myFunctions.findStories(post);

      const expectedDate = new Date("2024-06-15T22:31:07.000Z").getTime();
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
      expect(stories[0]).to.have.property("importance").that.is.within(0.0, 0.1);
      expect(new Date(stories[0].happenedAt).getTime()).to.be.closeTo(expectedDate, deltaTime);
      expect(stories[0].lat).to.be.closeTo(31.5, deltaLatLong);
      expect(stories[0].long).to.be.closeTo(34.47, deltaLatLong);
      expect(stories[0].photos).to.be.an("array").that.has.lengthOf(0);
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

      myFunctions.__set__("searchVectors", searchVectorsStub);
      myFunctions.__set__("writeTrainingData", writeTrainingDataStub);

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

      const stories = await myFunctions.findStories(post);

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
  });

  afterEach(() => {
    sinon.restore();
  });
});
