# Old docs site redirect

This folder is deployed to the old `flutter-ui-payment` Netlify site (id `d9b5f0fb-8ed1-44c4-8a89-d7daebdc6936`), so every https://flutter-ui-payment.netlify.app URL returns a 301 to the same path on https://rakit-ui.netlify.app (D117). It is not part of the Astro build.

Deploy from `website/`:

```sh
netlify deploy --prod --dir redirect-old-site --site d9b5f0fb-8ed1-44c4-8a89-d7daebdc6936
```

The docs themselves deploy to the `rakit-ui` site (id `4dbabf95-de04-4c30-aeae-e95069a73272`).
