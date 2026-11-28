const original = $response.body;

if (typeof original !== "string") {
  $done({});
} else {
  const body = original
    .replaceAll("30tb.ai.pro.m", "30tb.m")
    .replaceAll("20tb.m.v2", "20tb.m");
  $done(body === original ? {} : { body });
}