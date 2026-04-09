#import "../src/shipshop.typ": *

#let myhtml = ```html
<div style="font-family: 'TeX Gyre Schola', sans-serif;">
  <h1>Lorem Ipsum</h1>
  <h2>Hello World</h2>
  <div>
    <p>This is a <strong>paragraph</strong>.</p>
    <p style="color: #FF0099; font-size: 17pt; text-decoration: underline; font-family: 'Ubuntu Mono', monospace;">This is another paragraph.</p>
    <p>Can we add<br>a linebreak?</p>
    <div style="padding-left: 33pt;">
      <p ><code style="margin-right: 33pt;">style="padding-left: 33pt;"</code> Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem, ut postea variari voluptas distinguique possit, augeri amplificarique non possit.</p>
    </div>
    <div style="padding: 73pt; text-align: justify; border: 2mm solid green;">
      <p ><code style="margin-right: 30mm;">style="padding: 73pt;"</code> Lorem ipsum dolor sit amet,
      consectetur adipiscing elit,
      sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo,
      cum corpore dolemus,
      fieri tamen permagna <span style="background-color: yellow;">accessio potest</span>,
      si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem,
      ut postea variari voluptas distinguique possit, augeri amplificarique non possit.</p>
    </div>
  </div>
</div>
<hr>
```
// #lorem(120)



#[
  #set heading(numbering: "1.1.1.1.1.  ")
  #html-render(myhtml.text)
]


#pagebreak()
#myhtml


/*
  w=y ntypstpro examples/demo1.typ
*/
