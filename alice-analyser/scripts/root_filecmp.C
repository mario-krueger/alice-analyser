// exact comparison of two root files (any layout), every object by full path (directories and TList/TObjArray
// recursed): TH1 binning (all axes, edges), entries, contents and errors per cell (+ bin entries of profiles);
// THn/THnSparse axes and every filled bin by its coordinates; TGraph* points and errors; TF1 parameters, errors,
// chi2, ndf, range. other classes are not compared and counted as "unchecked". last line:
//   "<n> objects: <n> identical, <n> unchecked (class only), <n> different, <n> only in A, <n> only in B"
// a pass needs 0 unchecked (or a reason), 0 different, 0 only in A, 0 only in B. returns 0 on a pass, 1 otherwise.
// copy this file into your study/tests folder first: ACLiC writes its build products next to it.
//   root -l -b -q 'root_filecmp.C+("a.root","b.root")'
#include <TFile.h>
#include <TKey.h>
#include <TDirectory.h>
#include <TCollection.h>
#include <TH1.h>
#include <TProfile.h>
#include <TAxis.h>
#include <THnBase.h>
#include <TGraph.h>
#include <TF1.h>
#include <cmath>
#include <map>
#include <string>
#include <vector>
#include <cstdio>
// equal values, or both nan (nan != nan in c++; e.g. nan fit errors would otherwise always differ)
static bool eqv(double a, double b) { return a == b || (std::isnan(a) && std::isnan(b)); }
static void add(TObject* o, std::map<std::string, TObject*>& m, const std::string& p);
static void collectColl(TCollection* c, std::map<std::string, TObject*>& m, const std::string& path)
{
  std::map<std::string, int> seen; // same name twice in a list: number them
  for (auto o : *c) {
    if (!o) continue;
    std::string n = o->GetName();
    int k = seen[n]++;
    add(o, m, path + "/" + n + (k ? "#" + std::to_string(k) : ""));
  }
}
static void collect(TDirectory* d, std::map<std::string, TObject*>& m, const std::string& path)
{
  for (auto k : *d->GetListOfKeys()) {
    auto key = (TKey*)k;
    add(key->ReadObj(), m, path + "/" + key->GetName() + ";" + std::to_string(key->GetCycle()));
  }
}
static void add(TObject* o, std::map<std::string, TObject*>& m, const std::string& p)
{
  if (auto sub = dynamic_cast<TDirectory*>(o)) { collect(sub, m, p); return; }
  if (auto col = dynamic_cast<TCollection*>(o)) { collectColl(col, m, p); return; }
  m[p] = o;
}
static bool sameAxis(const TAxis* a, const TAxis* b)
{
  if (a->GetNbins() != b->GetNbins()) return false;
  for (int i = 1; i <= a->GetNbins() + 1; ++i)
    if (!eqv(a->GetBinLowEdge(i), b->GetBinLowEdge(i))) return false;
  return true;
}
int root_filecmp(const char* fa, const char* fb)
{
  TFile a(fa, "READ"), b(fb, "READ");
  if (a.IsZombie() || b.IsZombie()) { printf("cannot open %s or %s\n", fa, fb); return 1; }
  std::map<std::string, TObject*> ma, mb;
  collect(&a, ma, ""); collect(&b, mb, "");
  int same = 0, diff = 0, unchecked = 0, onlyA = 0, onlyB = 0;
  for (auto& [n, oa] : ma) {
    if (!mb.count(n)) { onlyA++; printf("  only in A: %s\n", n.c_str()); continue; }
    auto ob = mb[n];
    bool eq = std::string(oa->ClassName()) == ob->ClassName();
    if (auto ha = dynamic_cast<TH1*>(oa)) {
      auto hb = dynamic_cast<TH1*>(ob);
      eq = eq && hb && ha->GetNcells() == hb->GetNcells() && sameAxis(ha->GetXaxis(), hb->GetXaxis()) &&
           sameAxis(ha->GetYaxis(), hb->GetYaxis()) && sameAxis(ha->GetZaxis(), hb->GetZaxis()) &&
           eqv(ha->GetEntries(), hb->GetEntries());
      auto pa = dynamic_cast<TProfile*>(oa);
      auto pb = dynamic_cast<TProfile*>(ob);
      for (int c = 0; eq && c < ha->GetNcells(); ++c) {
        eq = eqv(ha->GetBinContent(c), hb->GetBinContent(c)) && eqv(ha->GetBinError(c), hb->GetBinError(c));
        if (eq && pa && pb) eq = eqv(pa->GetBinEntries(c), pb->GetBinEntries(c));
      }
    } else if (auto na = dynamic_cast<THnBase*>(oa)) {
      auto nb = dynamic_cast<THnBase*>(ob);
      eq = eq && nb && na->GetNdimensions() == nb->GetNdimensions() && na->GetNbins() == nb->GetNbins();
      for (int d = 0; eq && d < na->GetNdimensions(); ++d) eq = sameAxis(na->GetAxis(d), nb->GetAxis(d));
      std::vector<Int_t> coord(eq ? na->GetNdimensions() : 0);
      // every filled bin of A must exist in B at the same coordinates with the same content and error;
      // with equal numbers of filled bins this also excludes extra bins in B
      for (Long64_t i = 0; eq && i < na->GetNbins(); ++i) {
        double ca = na->GetBinContent(i, coord.data());
        double ea = na->GetBinError2(i);
        Long64_t j = nb->GetBin(coord.data(), kFALSE);
        eq = j >= 0 && eqv(ca, nb->GetBinContent(j)) && eqv(ea, nb->GetBinError2(j));
      }
    } else if (auto ga = dynamic_cast<TGraph*>(oa)) {
      auto gb = dynamic_cast<TGraph*>(ob);
      eq = eq && gb && ga->GetN() == gb->GetN();
      for (int i = 0; eq && i < ga->GetN(); ++i)
        eq = eqv(ga->GetX()[i], gb->GetX()[i]) && eqv(ga->GetY()[i], gb->GetY()[i]) &&
             eqv(ga->GetErrorXlow(i), gb->GetErrorXlow(i)) && eqv(ga->GetErrorXhigh(i), gb->GetErrorXhigh(i)) &&
             eqv(ga->GetErrorYlow(i), gb->GetErrorYlow(i)) && eqv(ga->GetErrorYhigh(i), gb->GetErrorYhigh(i));
    } else if (auto f1 = dynamic_cast<TF1*>(oa)) {
      auto f2 = dynamic_cast<TF1*>(ob);
      eq = eq && f2 && f1->GetNpar() == f2->GetNpar() && eqv(f1->GetChisquare(), f2->GetChisquare()) && f1->GetNDF() == f2->GetNDF() &&
           eqv(f1->GetXmin(), f2->GetXmin()) && eqv(f1->GetXmax(), f2->GetXmax()) && std::string(f1->GetTitle()) == f2->GetTitle();
      for (int i = 0; eq && i < f1->GetNpar(); ++i) eq = eqv(f1->GetParameter(i), f2->GetParameter(i)) && eqv(f1->GetParError(i), f2->GetParError(i));
    } else {
      if (eq) { unchecked++; printf("  unchecked (class only): %s [%s]\n", n.c_str(), oa->ClassName()); continue; }
    }
    (eq ? same : diff)++;
    if (!eq) printf("  DIFFERENT: %s\n", n.c_str());
  }
  for (auto& [n, o] : mb) if (!ma.count(n)) { onlyB++; printf("  only in B: %s\n", n.c_str()); }
  printf("%d objects: %d identical, %d unchecked (class only), %d different, %d only in A, %d only in B\n",
         (int)ma.size(), same, unchecked, diff, onlyA, onlyB);
  return (unchecked || diff || onlyA || onlyB) ? 1 : 0;
}
