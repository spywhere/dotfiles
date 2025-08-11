// ==UserScript==
// @name         Sponsorblock
// @version      1.1.0
// @description  Skip sponsor segments automatically
// @author       afreakk
// @author          vongaisberg
// @match        *://*.youtube.com/*
// @exclude      *://*.youtube.com/subscribe_embed?*
// ==/UserScript==
const delay = 1000;

const tryFetchSkipSegments = (videoID) =>

    fetch(`https://sponsor.ajay.app/api/skipSegments?videoID=${videoID}`)
        .then((r) => r.json())
        .then((rJson) =>
            rJson.filter((a) => a.actionType === 'skip').map((a) => a.segment)
        )
        .catch(
            (e) =>
                console.log(
                    `Sponsorblock: failed fetching skipSegments for ${videoID}, reason: ${e}`
                ) || []
        );

const skipSegments = async () => {
    const videoID = new URL(document.location).searchParams.get('v');
    if (!videoID) {
        return;
    }
    const key = `segmentsToSkip-${videoID}`;
    window[key] = window[key] || (await tryFetchSkipSegments(videoID));
    for (const v of document.querySelectorAll('video')) {
        if (Number.isNaN(v.duration)) continue;
        for (const [start, end] of window[key]) {
            if (v.currentTime < end && v.currentTime >= start) {
                console.log(`Sponsorblock: skipped video @${v.currentTime} from ${start} to ${end}`);
                v.currentTime = end;
                return
            }
            const timeToSponsor = (start - v.currentTime) / v.playbackRate;
            if (v.currentTime < start && timeToSponsor < (delay / 1000)) {
                console.log(`Sponsorblock: Almost at sponsor segment, sleep for ${timeToSponsor * 1000}ms`);
                setTimeout(skipSegments, timeToSponsor * 1000);
            }
        }
    }
};
if (!window.skipSegmentsIntervalID) {
    window.skipSegmentsIntervalID = setInterval(skipSegments, delay);
}
