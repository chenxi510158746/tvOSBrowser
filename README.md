tvOS Browser
=============


Navigateur web pour tvOS utilisant une API propriétaire (UIWebView).
Il est nécessaire d'éditer les lignes suivantes dans le fichier Availability.h de XCode pour compiler correctement.

```
Availability.h pour AppleTV est situé dans Xcode > Contents > Developer > Platforms > AppleTVOS.platform > Developer > SDKs > AppleTVOS.sdk > usr > include
Availability.h pour le simulateur AppleTV est situé dans Xcode > Contents > Developer > Platforms > AppleTVSimulator.platform > Developer > SDKs > AppleTVSimulator.sdk > usr > include
```
Remplacez les lignes :
```
#define __TVOS_UNAVAILABLE                    __OS_AVAILABILITY(tvos,unavailable)
#define __TVOS_PROHIBITED                     __OS_AVAILABILITY(tvos,unavailable)
```
Par les lignes :
```
#define __TVOS_UNAVAILABLE_NOTQUITE                    __OS_AVAILABILITY(tvos,unavailable)
#define __TVOS_PROHIBITED_NOTQUITE                     __OS_AVAILABILITY(tvos,unavailable)
```

Comment utiliser tvOSBrowser
=============

- Double cliquer au centre de la zone tactile de la télécommande pour passer du mode curseur au mode ascenseur.
- Toucher la zone tactile pour cliquer en mode curseur.
- Le bouton Menu permet de revenir à la page précédente.
- Le bouton Lecture/Pause permet de saisir une URL, une recherche Google ou de recharger la page courante.
- Un double clic sur le bouton Menu ou Lecture/Pause permet de faire apparaitre une menu comprenant les favoris, l'historique, les paramètres de la page d'accueil, le UserAgent, la purge du cache et des cookies.
