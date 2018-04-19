import java.sql.*;
import java.util.List;
import java.util.ArrayList;

// If you are looking for Java data structures, these are highly useful.
// Remember that an important part of your mark is for doing as much in SQL (not Java) as you can.
// Solutions that use only or mostly Java will not receive a high mark.
//import java.util.ArrayList;
//import java.util.Map;
//import java.util.HashMap;
//import java.util.Set;
//import java.util.HashSet;
public class Assignment2 extends JDBCSubmission {

    public Assignment2() throws ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
    }

    @Override
    public boolean connectDB(String url, String username, String password) {
        // Implement this method!
        try{
          connection = DriverManager.getConnection(url, username, password);
          return true;
        }
        catch (SQLException se){
          return false;
        }

    }

    @Override
    public boolean disconnectDB() {
        // Implement this method!
        try{
          connection.close();
          return true;
        }
        catch (SQLException se){
          return false;
        }
    }

    @Override
    public ElectionCabinetResult electionSequence(String countryName) {
        // Implement this method!
        String cabinetsFormed;
        ResultSet rs;
        List<Integer> arr = new ArrayList<Integer>();
        List<Integer> arr1 = new ArrayList<Integer>();
        try{
          cabinetsFormed = "select c1.election_id, c1.e_type, c1.e_date,"+
          " c1.start_date, c1.cabinet_id, c2.name as country_name from"+
          " (select distinct e.id as election_id, e.e_type, e.e_date,"+
          " c.start_date, c.id as cabinet_id, e.country_id from election e"+
          " left join cabinet c on e.id = c.election_id and"+
          " e.country_id = c.country_id) c1, country c2 where"+
          " c1.country_id = c2.id and c2.name=?"+
          " order by e_date DESC, start_date ASC";

          PreparedStatement ps = connection.prepareStatement(cabinetsFormed);
          // Insert that string into the PreparedStatement and execute it.
          ps.setString(1, countryName);
          rs = ps.executeQuery();

          // Iterate through the result set and report on each tuple.

          Integer prev_ep_id = null;
          String prev_etype = "";
          List<Integer> previous_cabinet_id = new ArrayList<Integer>();

          while (rs.next()) {
              Integer electionId = rs.getInt("election_id");
              Integer cabinetId = rs.getInt("cabinet_id");
              String eType = rs.getString("e_type");
              //System.out.println(cabinetId);
              if (prev_etype.equals("") && previous_cabinet_id.size() == 0
                  && !cabinetId.equals(0)){
                arr.add(electionId);
                arr1.add(cabinetId);
                previous_cabinet_id.add(0, cabinetId);
                prev_etype = eType;
              }
              else if (previous_cabinet_id.size() == 0
                && !prev_etype.equals(eType) && !prev_etype.equals("")){
                arr.add(electionId);
                arr1.add(cabinetId);
                previous_cabinet_id.add(0, cabinetId);
                prev_etype = eType;
              }
              else if (cabinetId > 0 && eType.equals(prev_etype)
                && !prev_etype.equals("")){
                arr.add(electionId);
                arr1.add(cabinetId);
                previous_cabinet_id.add(0, cabinetId);
                prev_etype = eType;
              }
              else if (cabinetId.equals(0) && !eType.equals(prev_etype)
                && !prev_etype.equals("")){
                for (int i=0; i < previous_cabinet_id.size(); i++){
                  arr.add(electionId);
                  arr1.add(previous_cabinet_id.get(i));
                }
                previous_cabinet_id = new ArrayList<Integer>();
                prev_etype = eType;
              }
          }
        }
        catch (SQLException e){
          System.out.println("SQL Error");
        }
        ElectionCabinetResult result = new ElectionCabinetResult(arr, arr1);
        return result;
    }


    @Override
    public List<Integer> findSimilarPoliticians(Integer politicianName, Float threshold) {
        // Implement this method!

        String politician;
        ResultSet rs;
        List<Integer> arr = new ArrayList<Integer>();

        try{
          politician = "select p1.description as d1, p1.comment as c1, p2.id,"
          +" p2.description as d2, p2.comment as c2"+
          " from politician_president p1, politician_president p2"
          +" where p1.id = ? and p1.id <> p2.id";
          PreparedStatement ps = connection.prepareStatement(politician);
          // Insert that string into the PreparedStatement and execute it.
          ps.setInt(1, politicianName);
          rs = ps.executeQuery();

          // Iterate through the result set and report on each tuple.
          while (rs.next()) {
              String d1 = rs.getString("d1") + " " + rs.getString("c1");
              String d2 = rs.getString("d2") + " " + rs.getString("c2");
              Integer iD = rs.getInt("id");
              double result = similarity(d1,d2);
              if ((float)result >= threshold){
                arr.add(iD);
              }
          }
        }
        catch (SQLException e){
          System.out.println("SQL Error");
        }
        return arr;
    }

    public static void main(String[] args) {
        // You can put testing code in here. It will not affect our autotester.
        try{
          Assignment2 a2 = new Assignment2();
          a2.connectDB("jdbc:postgresql://localhost:5432/csc343h-koonergu?currentSchema=parlgov", "koonergu", "");
          //System.out.println("Hello");
          System.out.println(a2.electionSequence("Germany"));
          //System.out.println(a2.findSimilarPoliticians(9, (float)0.10));
          a2.disconnectDB();
        }
        catch (ClassNotFoundException ce){
          System.out.println("Error");
        }
    }

}
