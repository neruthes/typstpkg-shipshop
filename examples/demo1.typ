#import "../src/shipshop.typ": *


// #let myhtml =
// #lorem(120)


#let try_piece(myhtml) = [
  #myhtml
  #pagebreak(weak: true)
  #set heading(numbering: "1.1.1.1.1.  ")
  #html-render(
    myhtml.text,
    debug: true,
  )
  #pagebreak(weak: true)
]

#try_piece(
  ```html
  <div style="font-family: 'TeX Gyre Schola', sans-serif;">
    <h1>Lorem Ipsum</h1>
    <h2>Hello World</h2>
    <div>
      <p>This is a <strong>paragraph</strong>.</p>
      <p style="color: #FF0099; font-size: 17pt; text-decoration: underline; font-family: 'Ubuntu Mono', monospace;">This is another paragraph.</p>
      <p>Can we add<br>a linebreak?</p>
      <div style="padding-left: 21pt;">
        <p ><code style="margin-right: 21pt;">style="padding-left: 21pt;"</code> Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem, ut postea variari voluptas distinguique possit, augeri amplificarique non possit.</p>
      </div>
      <div style="padding: 43pt; text-align: justify; border: 2mm solid green;">
        <p ><code style="margin-right: 30mm;">style="padding: 43pt;"</code> Lorem ipsum dolor sit amet,
        consectetur adipiscing elit,
        sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo,
        cum corpore dolemus,
        <span style="background-color: yellow;">fieri tamen</span> permagna accessio potest,
        si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem,
        ut postea variari voluptas distinguique possit, augeri amplificarique non possit.</p>
      </div>
      <span style="width: 50mm; height: 25mm; background-color: gray;"></span>
    </div>
  </div>
  <hr>
  ```,
)

#try_piece(
  ```html
  <pre lang="js">
  const ccc = { ddd: `xx${0.1 + 0.2}yy` };
  const zz = { ddd: `xx${0.1 + 0.2}yy` };
  const yy = { ddd: `xx${0.1 + 0.2}yy` };
  </pre>
  <pre lang="typst">
  #let aa = (bb: "33" + repr(0.1 + 0.2))
  #let aa = (bb: "33" + repr(0.1 + 0.2))
  #let aa = (bb: "33" + repr(0.1 + 0.2))
  #let aa = (bb: "33" + repr(0.1 + 0.2))
  </pre>
  <div style="width: 100%; background-color: #dddddd;">
    <span style="display: inline; height: 10mm; width: 20%; background-color: #77bbff;">#######</span>
    <span style="display: inline; height: 10mm; width: 35%; background-color: #ff4477;">#######</span>
  </div>
  ```,
)


#try_piece(
  ```html
  <table style="width: 90%">
    <thead>
      <tr>
        <th>Name</th><th>Age</th><th>Address</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Alice</td><td>25</td><td>1 Infinite Loop, Cupertino, CA 95014, US</td>
        <td>Bob</td><td>27</td><td>10 Downing St, Westminster, London, UK</td>
        <td>Charles</td><td>29</td><td>Tamar, Hong Kong SAR</td>
      </tr>
    </tbody>
  </table>
  ```,
)



#__std_test_case_001


/*
  w=y ntypstpro examples/demo1.typ
  cfoss2 _dist/examples/demo1.pdf
*/
